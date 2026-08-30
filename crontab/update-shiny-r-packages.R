# 仅当 Git 仓库有新 commit 时才安装包
# 通过比较本地 RemoteSha 和远程最新 commit hash 判断是否需要更新

# 带时间戳的日志输出
log <- function(...) {
  timestamp <- format(Sys.time(), "[%Y-%m-%d %H:%M:%S]")
  message(timestamp, " ", ...)
}

install_git_if_updated <- function(url, package_name, lib = NULL, max_attempts = 3) {
  # 检查包是否已安装
  installed <- tryCatch(
    suppressWarnings(packageVersion(package_name, lib.loc = lib)),
    error = function(e) NULL
  )

  if (is.null(installed)) {
    log("[", package_name, "] 包未安装，执行安装...")
    return(try_install_git(url, package_name, lib, max_attempts))
  }

  # 获取本地安装的 RemoteSha
  desc <- packageDescription(package_name, lib.loc = lib)
  local_sha <- desc$RemoteSha

  if (is.null(local_sha)) {
    log("[", package_name, "] 无法获取本地 commit hash，执行安装...")
    return(try_install_git(url, package_name, lib, max_attempts))
  }

  # 获取远程最新 commit hash
  log("[", package_name, "] 检查远程仓库更新...")
  remote_sha <- tryCatch({
    # 解析 Git URL 获取远程信息
    if (grepl("github", url, ignore.case = TRUE)) {
      # 从 URL 提取 owner/repo
      repo_path <- sub(".*github\\.com[/:]([^/]+/[^/]+).*", "\\1", url)
      repo_path <- sub("\\.git$", "", repo_path)
      api_url <- sprintf("https://api.github.com/repos/%s/commits/HEAD", repo_path)
      
      # 添加超时和错误处理
      resp <- tryCatch({
        # 设置全局超时选项
        old_timeout <- getOption("timeout")
        options(timeout = 30)
        on.exit(options(timeout = old_timeout), add = TRUE)
        jsonlite::fromJSON(api_url)
      }, error = function(e) {
        log("[", package_name, "] GitHub API 请求失败: ", e$message)
        return(NULL)
      })
      
      if (is.null(resp)) return(NULL)
      resp$sha
    } else {
      log("[", package_name, "] 非 GitHub 仓库，跳过版本检查直接安装")
      return(try_install_git(url, package_name, lib, max_attempts))
    }
  }, error = function(e) {
    log("[", package_name, "] 无法获取远程 commit: ", e$message)
    return(NULL)
  })

  if (is.null(remote_sha)) {
    log("[", package_name, "] 跳过安装")
    return(invisible(FALSE))
  }

  # 比较 commit hash（取前 7 位比较，因为 Git 的 short SHA 通常是 7 位）
  local_short <- substr(local_sha, 1, 7)
  remote_short <- substr(remote_sha, 1, 7)

  if (local_short == remote_short) {
    log("[", package_name, "] 版本无更新 (commit: ", local_short, ")，跳过安装")
    return(invisible(FALSE))
  } else {
    log("[", package_name, "] 发现新版本 (本地: ", local_short, " -> 远程: ", remote_short, ")，执行安装...")
    return(try_install_git(url, package_name, lib, max_attempts))
  }
}

# 带重试机制的安装函数
try_install_git <- function(url, package_name, lib = NULL, max_attempts = 3) {
  for (attempt in 1:max_attempts) {
    if (attempt > 1) {
      log("[", package_name, "] 重试安装 (尝试 ", attempt, "/", max_attempts, ")...")
      Sys.sleep(5)
    }
    
    result <- tryCatch({
      remotes::install_git(url, dependencies = TRUE, lib = lib, upgrade = "never", quiet = TRUE)
      
      # 安装后验证
      tryCatch({
        suppressPackageStartupMessages(
          library(package_name, lib.loc = lib, character.only = TRUE)
        )
        log("[", package_name, "] 安装完成并验证通过")
        return(invisible(TRUE))
      }, error = function(e) {
        log("[", package_name, "] 包安装成功但无法加载: ", e$message)
        return(invisible(FALSE))
      })
    }, error = function(e) {
      log("[", package_name, "] 安装失败: ", e$message)
      return(invisible(FALSE))
    })
    
    if (result) return(invisible(TRUE))
  }
  
  log("[", package_name, "] 安装最终失败，将在下次 crontab 运行时重试")
  return(invisible(FALSE))
}

# 设置库路径
lib_path <- "/usr/local/lib/R/extra-library"

# 安装列表
packages <- list(
  list(url = "https://ghfast.top/https://github.com/IOBR/IOBR", name = "IOBR"),
  list(url = "https://ghfast.top/https://github.com/WangLabCSU/PERCEPTIONx", name = "PERCEPTIONx")
  # list(url = "https://ghfast.top/https://github.com/openbiox/UCSCXenaShiny", name = "UCSCXenaShiny")
)

# 执行安装检查
for (pkg in packages) {
  install_git_if_updated(url = pkg$url, package_name = pkg$name, lib = lib_path)
}

log("远程 R 包更新检查完成")

# 注意：本地 Git 仓库（如 ImmunoFusion）的 pull 操作由宿主机脚本
# crontab/update-packages.sh 执行，以保证文件所有权正确。
# 容器内默认 root，直接 pull 会破坏宿主机仓库所有权。