# 仅当 Git 仓库有新 commit 时才安装包
# 通过比较本地 RemoteSha 和远程最新 commit hash 判断是否需要更新

install_git_if_updated <- function(url, package_name, lib = NULL) {
  # 检查包是否已安装
  installed <- tryCatch(
    suppressWarnings(packageVersion(package_name, lib.loc = lib)),
    error = function(e) NULL
  )

  if (is.null(installed)) {
    message(sprintf("[%s] 包未安装，执行安装...", package_name))
    remotes::install_git(url, dependencies = TRUE, lib = lib, upgrade = "never")
    return(invisible(TRUE))
  }

  # 获取本地安装的 RemoteSha
  desc <- packageDescription(package_name, lib.loc = lib)
  local_sha <- desc$RemoteSha

  if (is.null(local_sha)) {
    message(sprintf("[%s] 无法获取本地 commit hash，执行安装...", package_name))
    remotes::install_git(url, dependencies = TRUE, lib = lib, upgrade = "never")
    return(invisible(TRUE))
  }

  # 获取远程最新 commit hash
  message(sprintf("[%s] 检查远程仓库更新...", package_name))
  remote_sha <- tryCatch({
    # 解析 Git URL 获取远程信息
    if (grepl("github", url, ignore.case = TRUE)) {
      # 从 URL 提取 owner/repo
      repo_path <- sub(".*github\\.com[/:]([^/]+/[^/]+).*", "\\1", url)
      repo_path <- sub("\\.git$", "", repo_path)
      api_url <- sprintf("https://api.github.com/repos/%s/commits/HEAD", repo_path)
      resp <- jsonlite::fromJSON(api_url)
      resp$sha
    } else {
      message(sprintf("[%s] 非 GitHub 仓库，跳过版本检查直接安装", package_name))
      remotes::install_git(url, dependencies = TRUE, lib = lib, upgrade = "never")
      return(invisible(TRUE))
    }
  }, error = function(e) {
    message(sprintf("[%s] 无法获取远程 commit: %s", package_name, e$message))
    return(NULL)
  })

  if (is.null(remote_sha)) {
    message(sprintf("[%s] 跳过安装", package_name))
    return(invisible(FALSE))
  }

  # 比较 commit hash（取前 7 位比较，因为 Git 的 short SHA 通常是 7 位）
  local_short <- substr(local_sha, 1, 7)
  remote_short <- substr(remote_sha, 1, 7)

  if (local_short == remote_short) {
    message(sprintf("[%s] 版本无更新 (commit: %s)，跳过安装", package_name, local_short))
    return(invisible(FALSE))
  } else {
    message(sprintf("[%s] 发现新版本 (本地: %s -> 远程: %s)，执行安装...",
                   package_name, local_short, remote_short))
    remotes::install_git(url, dependencies = TRUE, lib = lib, upgrade = "never")
    return(invisible(TRUE))
  }
}

# 设置库路径
lib_path <- "/usr/local/lib/R/extra-library"

# 安装列表
packages <- list(
  list(url = "https://ghfast.top/https://github.com/IOBR/IOBR", name = "IOBR")
  # list(url = "https://ghfast.top/https://github.com/openbiox/UCSCXenaShiny", name = "UCSCXenaShiny")
)

# 执行安装检查
for (pkg in packages) {
  install_git_if_updated(url = pkg$url, package_name = pkg$name, lib = lib_path)
}

# 注意：本地 Git 仓库（如 ImmunoFusion）的 pull 操作由宿主机脚本
# crontab/update-packages.sh 执行，以保证文件所有权正确。
# 容器内默认 root，直接 pull 会破坏宿主机仓库所有权。