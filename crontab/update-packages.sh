#!/bin/bash
# crontab /home/data/shiny-server/crontab/crontab.txt
# 每 12 小时检查并更新 Git 仓库（宿主机）和 R 包（容器内）
# 注：crontab 以 wsx 用户运行，git 操作必须在宿主机执行以保证文件所有权正确；
#     容器内默认 root，直接 pull 会破坏宿主机仓库所有权。

set -uo pipefail
cd /home/data/shiny-server

# === Git 仓库更新（宿主机执行，保证所有权正确）===
# 格式："路径 分支"
GIT_REPOS=(
  "/home/data/shiny-server/apps/ImmunoFusion main"
)

update_git_repo() {
  local repo_path="$1"
  local branch="${2:-main}"
  local repo_name
  repo_name=$(basename "$repo_path")

  if [ ! -d "$repo_path/.git" ]; then
    echo "[$repo_name] 不是 git 仓库或不存在: $repo_path"
    return 0
  fi

  echo "[$repo_name] 检查远程仓库更新..."
  git -C "$repo_path" fetch origin 2>&1 | sed 's/^/  /'

  local local_sha remote_sha
  local_sha=$(git -C "$repo_path" rev-parse HEAD 2>/dev/null)
  remote_sha=$(git -C "$repo_path" rev-parse "origin/$branch" 2>/dev/null)

  if [ -z "$local_sha" ] || [ -z "$remote_sha" ]; then
    echo "[$repo_name] 无法获取 commit hash，跳过"
    return 0
  fi

  if [ "$local_sha" = "$remote_sha" ]; then
    echo "[$repo_name] 版本无更新 (commit: ${local_sha:0:7})，跳过 pull"
  else
    echo "[$repo_name] 发现新版本 (本地: ${local_sha:0:7} -> 远程: ${remote_sha:0:7})，执行 pull..."
    git -C "$repo_path" pull origin "$branch" 2>&1 | sed 's/^/  /'
    echo "[$repo_name] pull 完成"
  fi
  return 0
}

echo "=== 更新 Git 仓库（宿主机）==="
for entry in "${GIT_REPOS[@]}"; do
  # shellcheck disable=SC2086
  update_git_repo $entry
done

# === 容器内检查并同步 R 包应用 ===
# 独立于 git pull 结果，每次都验证已安装包与源码一致性
# 通过比对源码 commit hash 与已安装包的 SourceCommit 字段

echo ""
echo "=== 同步 R 包应用（容器内）==="

# 构建仓库列表：name:commit 格式，传给容器脚本
REPO_INFO=""
for entry in "${GIT_REPOS[@]}"; do
  repo_path=$(echo "$entry" | awk '{print $1}')
  repo_name=$(basename "$repo_path")
  if [ -f "$repo_path/DESCRIPTION" ]; then
    commit=$(git -C "$repo_path" rev-parse HEAD 2>/dev/null)
    REPO_INFO="${REPO_INFO}${repo_name}:${commit} "
  fi
done

# 容器内执行同步检查和安装
# 注意：docker compose exec 使用 -e VAR=value 传递环境变量
docker compose exec -T -u shiny -e REPO_INFO="$REPO_INFO" shiny-server Rscript -e '
repo_info <- Sys.getenv("REPO_INFO", "")
if (repo_info == "") {
  cat("无 R 包仓库需要检查\n")
} else {
  repos <- strsplit(trimws(repo_info), " +")[[1]]
  lib_path <- "/usr/local/lib/R/extra-library"
  
  for (item in repos) {
    if (item == "") next
    parts <- strsplit(item, ":")[[1]]
    repo_name <- parts[1]
    source_commit <- parts[2]
    
    cat(sprintf("[%s] 检查同步状态...\n", repo_name))
    
    pkg_path <- file.path(lib_path, repo_name)
    source_desc <- file.path("/srv/shiny-server", repo_name, "DESCRIPTION")
    
    need_install <- FALSE
    
    if (!dir.exists(pkg_path)) {
      cat(sprintf("  已安装包不存在，需安装\n"))
      need_install <- TRUE
    } else {
      # 直接读取已安装包的 DESCRIPTION 文件（避免 packageDescription 缓存问题）
      installed_desc_path <- file.path(pkg_path, "DESCRIPTION")
      installed_commit <- NULL
      
      if (file.exists(installed_desc_path)) {
        desc_lines <- readLines(installed_desc_path, warn = FALSE)
        commit_line <- desc_lines[grepl("^SourceCommit:", desc_lines)]
        if (length(commit_line) > 0) {
          installed_commit <- sub("^SourceCommit:\\s*", "", commit_line[1])
        }
      }
      
      if (is.null(installed_commit) || installed_commit == "") {
        cat(sprintf("  已安装包无 SourceCommit 元数据，需重装以注入\n"))
        need_install <- TRUE
      } else if (installed_commit != source_commit) {
        cat(sprintf("  commit 不一致: 已安装 %s != 源码 %s，需重装\n",
                    substr(installed_commit, 1, 7), substr(source_commit, 1, 7)))
        need_install <- TRUE
      } else {
        cat(sprintf("  同步正常 (commit: %s)\n", substr(source_commit, 1, 7)))
      }
    }
    
    if (need_install) {
      cat(sprintf("  正在安装...\n"))
      tryCatch({
        # 安装包
        remotes::install_local(
          file.path("/srv/shiny-server", repo_name),
          lib = lib_path,
          dependencies = TRUE,
          upgrade = "never",
          force = TRUE
        )
        
        # 注入 SourceCommit 到已安装包的 DESCRIPTION
        installed_desc_path <- file.path(pkg_path, "DESCRIPTION")
        if (file.exists(installed_desc_path)) {
          desc_lines <- readLines(installed_desc_path)
          # 移除旧的 SourceCommit（如有）
          desc_lines <- desc_lines[!grepl("^SourceCommit:", desc_lines)]
          # 添加新的 SourceCommit
          desc_lines <- c(desc_lines, paste0("SourceCommit: ", source_commit))
          writeLines(desc_lines, installed_desc_path)
          cat(sprintf("  已注入 SourceCommit: %s\n", substr(source_commit, 1, 7)))
        }
        
        cat(sprintf("  安装完成\n"))
      }, error = function(e) {
        cat(sprintf("  安装失败: %s\n", e$message))
      })
    }
  }
}
' 2>&1 | sed 's/^/  /'

echo ""
echo "=== 更新远程 R 包（容器内）==="
cat /home/data/shiny-server/crontab/update-shiny-r-packages.R | docker compose exec -T shiny-server Rscript -