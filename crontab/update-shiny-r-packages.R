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

# 检查本地 Git 仓库是否有更新，如有则 pull 并安装依赖
# @param repo_path 本地仓库路径
# @param remote_name 远程名称，默认 "origin"
# @param branch 分支名称，默认 "main" 或 "master"
pull_git_repo_if_updated <- function(repo_path, remote_name = "origin", branch = NULL) {
  repo_name <- basename(repo_path)
  
  if (!dir.exists(repo_path)) {
    message(sprintf("[%s] 仓库路径不存在: %s", repo_name, repo_path))
    return(invisible(FALSE))
  }
  
  if (!dir.exists(file.path(repo_path, ".git"))) {
    message(sprintf("[%s] 不是 Git 仓库: %s", repo_name, repo_path))
    return(invisible(FALSE))
  }
  
  # 获取当前分支
  if (is.null(branch)) {
    branch <- tryCatch({
      output <- system2("git", c("-C", repo_path, "rev-parse", "--abbrev-ref", "HEAD"), 
                        stdout = TRUE, stderr = TRUE)
      trimws(output[1])
    }, error = function(e) "main")
    if (branch == "" || is.null(branch)) branch <- "main"
  }
  
  # 获取本地当前 commit
  local_sha <- tryCatch({
    output <- system2("git", c("-C", repo_path, "rev-parse", "HEAD"), 
                      stdout = TRUE, stderr = TRUE)
    trimws(output[1])
  }, error = function(e) NULL)
  
  if (is.null(local_sha) || local_sha == "") {
    message(sprintf("[%s] 无法获取本地 commit hash", repo_name))
    return(invisible(FALSE))
  }
  
  # 获取远程最新 commit（先 fetch）
  message(sprintf("[%s] 检查远程仓库更新...", repo_name))
  tryCatch({
    system2("git", c("-C", repo_path, "fetch", remote_name), 
            stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    message(sprintf("[%s] fetch 失败: %s", repo_name, e$message))
  })
  
  remote_sha <- tryCatch({
    output <- system2("git", c("-C", repo_path, "rev-parse", 
                               paste0(remote_name, "/", branch)), 
                      stdout = TRUE, stderr = TRUE)
    trimws(output[1])
  }, error = function(e) NULL)
  
  if (is.null(remote_sha) || remote_sha == "") {
    message(sprintf("[%s] 无法获取远程 commit hash", repo_name))
    return(invisible(FALSE))
  }
  
  local_short <- substr(local_sha, 1, 7)
  remote_short <- substr(remote_sha, 1, 7)
  
  if (local_short == remote_short) {
    message(sprintf("[%s] 版本无更新 (commit: %s)，跳过 pull", repo_name, local_short))
    return(invisible(FALSE))
  }
  
  # 有更新，执行 git pull
  message(sprintf("[%s] 发现新版本 (本地: %s -> 远程: %s)，执行 pull...",
                   repo_name, local_short, remote_short))
  
  pull_result <- tryCatch({
    output <- system2("git", c("-C", repo_path, "pull", remote_name, branch),
                      stdout = TRUE, stderr = TRUE)
    list(success = !any(grepl("error|fatal|failed", output, ignore.case = TRUE)),
         output = output)
  }, error = function(e) {
    list(success = FALSE, output = e$message)
  })
  
  if (!pull_result$success) {
    message(sprintf("[%s] pull 失败: %s", repo_name, 
                    paste(pull_result$output, collapse = " ")))
    return(invisible(FALSE))
  }
  
  message(sprintf("[%s] pull 成功", repo_name))
  
  # 检查是否有 renv.lock 文件，如有则更新依赖
  renv_lock <- file.path(repo_path, "renv.lock")
  if (file.exists(renv_lock)) {
    message(sprintf("[%s] 检测到 renv.lock，更新依赖...", repo_name))
    tryCatch({
      # 设置工作目录并运行 renv::restore()
      old_wd <- getwd()
      setwd(repo_path)
      on.exit(setwd(old_wd))
      
      # 检查 renv 是否已激活
      if (!file.exists(file.path(repo_path, "renv"))) {
        message(sprintf("[%s] renv 未初始化，尝试初始化...", repo_name))
        renv::init()
      } else {
        renv::restore(prompt = FALSE)
      }
      message(sprintf("[%s] 依赖更新完成", repo_name))
    }, error = function(e) {
      message(sprintf("[%s] 依赖更新失败: %s", repo_name, e$message))
    })
  }
  
  return(invisible(TRUE))
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

# 检查并更新本地 Git 仓库应用
git_repos <- list(
  list(path = "/srv/shiny-server/ImmunoFusion", branch = "main")
  # 可添加更多仓库
  # list(path = "/srv/shiny-server/other-app", branch = "master")
)

for (repo in git_repos) {
  pull_git_repo_if_updated(repo_path = repo$path, branch = repo$branch)
}