#!/bin/bash
# crontab /home/data/shiny-server/crontab/crontab.txt
# 每 12 小时检查并更新 Git 仓库（宿主机）和 R 包（容器内）
# 注：crontab 以 wsx 用户运行，git 操作必须在宿主机执行以保证文件所有权正确；
#     容器内默认 root，直接 pull 会破坏宿主机仓库所有权。

set -uo pipefail
cd /home/data/shiny-server

# 标记本次是否有仓库更新，用于触发容器内包重装
REPO_UPDATED=""

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
    return 1  # 返回 1 表示有更新
  fi
  return 0
}

echo "=== 更新 Git 仓库（宿主机）==="
for entry in "${GIT_REPOS[@]}"; do
  # shellcheck disable=SC2086
  if ! update_git_repo $entry; then
    REPO_UPDATED="$REPO_UPDATED $(echo $entry | awk '{print $1}')"
  fi
done

# === 容器内重装更新的 R 包应用 ===
# 当仓库代码有更新时，需在容器内重新安装对应的 R 包，
# 因为 app.R 优先加载已安装的包（library()）而非源码。
if [ -n "$REPO_UPDATED" ]; then
  echo ""
  echo "=== 容器内重装已更新的 R 包应用 ==="
  for repo_path in $REPO_UPDATED; do
    repo_name=$(basename "$repo_path")
    # 仅当源码包含 DESCRIPTION（即 R 包）时重装
    if [ -f "$repo_path/DESCRIPTION" ]; then
      echo "[$repo_name] 重新安装 R 包..."
      docker compose exec -T -u shiny shiny-server bash -c \
        "cd /srv/shiny-server/$repo_name && R CMD INSTALL . --library=/usr/local/lib/R/extra-library 2>&1" \
        | sed 's/^/  /'
      echo "[$repo_name] 安装完成"
    fi
  done
fi

echo ""
echo "=== 更新 R 包（容器内）==="
cat /home/data/shiny-server/crontab/update-shiny-r-packages.R | docker compose exec -T shiny-server Rscript -
