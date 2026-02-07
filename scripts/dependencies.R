cran_packages <- c(
  "pacman",
  "purrr",
  "tidyr",
  "stringr",
  "magrittr",
  "R.utils",
  "data.table",
  "dplyr",
  "ggplot2",
  "cowplot",
  "patchwork",
  "ggpubr",
  "plotly",
  "UpSetR",
  "UCSCXenaTools",
  "UCSCXenaShiny",
  "shiny",
  "shinyBS",
  "shinyjs",
  "shinyWidgets",
  "shinyalert",
  "shinyFiles",
  "shinyFeedback",
  "shinythemes",
  "shinyhelper",
  "shinycssloaders",
  "shinydashboard",
  "shinydashboardPlus",
  "survival",
  "survminer",
  "ezcox",
  "waiter",
  "colourpicker",
  "DT",
  "fs",
  "RColorBrewer",
  "ggcorrplot",
  "ggstatsplot",
  "zip",
  "msigdbr",
  "slickR",
  "funkyheatmap",
  "remotes"
)

github_packages <- c(
  "jespermaag/gganatogram",
  "ricardo-bion/ggradar"
)

bioconductor_packages <- c(
  "Biobase"
)

install_path <- "/usr/local/lib/R/extra-library"

if (!dir.exists(install_path)) {
  dir.create(install_path, recursive = TRUE, showWarnings = FALSE)
}

.libPaths(c(install_path, .libPaths()))

install_if_missing <- function(packages, install_fun, ...) {
  to_install <- packages[!packages %in% rownames(installed.packages(lib.loc = install_path))]
  if (length(to_install) > 0) {
    message(sprintf("Installing %d packages: %s", length(to_install), paste(to_install, collapse = ", ")))
    install_fun(to_install, lib = install_path, ...)
  } else {
    message("All packages already installed.")
  }
}

if (length(cran_packages) > 0) {
  message("Checking CRAN packages...")
  install_if_missing(cran_packages, install.packages, repos = "https://cran.rstudio.com/")
}

if (length(github_packages) > 0) {
  message("Checking GitHub packages...")
  if (!"remotes" %in% rownames(installed.packages())) {
    install.packages("remotes", repos = "https://cran.rstudio.com/")
  }
  library(remotes)
  
  # 辅助函数：尝试安装包，返回是否成功
  try_install <- function(install_expr, error_msg) {
    success <- FALSE
    tryCatch({
      withCallingHandlers({
        install_expr
        success <<- TRUE
      }, warning = function(w) {
        message(sprintf("Warning during install: %s", w$message))
        if (grepl("download|failed|error", w$message, ignore.case = TRUE)) {
          success <<- FALSE
          invokeRestart("muffleWarning")
        }
      })
    }, error = function(e) {
      message(sprintf("%s: %s", error_msg, e$message))
      success <<- FALSE
    })
    return(success)
  }
  
  for (pkg in github_packages) {
    pkg_name <- sub(".*/", "", sub("#.*", "", sub("@.*", "", pkg)))
    if (!pkg_name %in% rownames(installed.packages(lib.loc = install_path))) {
      message(sprintf("Installing package: %s", pkg_name))
      
      success <- FALSE
      
      if (pkg_name == "gganatogram" || pkg_name == "ggradar") {
        gitee_url <- if (pkg_name == "gganatogram") {
          "https://gitee.com/XenaShiny/gganatogram"
        } else {
          "https://gitee.com/XenaShiny/ggradar"
        }
        
        message(sprintf("Trying GitHub first for %s...", pkg_name))
        success <- try_install(
          install_github(pkg, lib = install_path),
          "GitHub install failed"
        )
        
        if (!success) {
          message("Trying Gitee fallback...")
          success <- try_install(
            install_git(gitee_url, lib = install_path),
            "Gitee install also failed"
          )
        }
      } else {
        success <- try_install(
          install_github(pkg, lib = install_path),
          "GitHub install failed"
        )
      }
      
      if (!success) {
        warning(sprintf("Failed to install %s!", pkg_name), immediate. = TRUE)
      }
    }
  }
}

if (length(bioconductor_packages) > 0) {
  message("Checking Bioconductor packages...")
  if (!"BiocManager" %in% rownames(installed.packages())) {
    install.packages("BiocManager", repos = "https://cran.rstudio.com/")
  }
  library(BiocManager)
  to_install <- bioconductor_packages[!bioconductor_packages %in% rownames(installed.packages(lib.loc = install_path))]
  if (length(to_install) > 0) {
    message(sprintf("Installing %d Bioconductor packages: %s", length(to_install), paste(to_install, collapse = ", ")))
    BiocManager::install(to_install, lib = install_path, ask = FALSE)
  } else {
    message("All Bioconductor packages already installed.")
  }
}

message("Checking UCSCXenaTools version...")
if ("UCSCXenaTools" %in% rownames(installed.packages())) {
  if (packageVersion("UCSCXenaTools") < "1.4.4") {
    message("Updating UCSCXenaTools to version >= 1.4.4...")
    tryCatch({
      install.packages("UCSCXenaTools", repos = "https://cran.rstudio.com/", lib = install_path)
    }, error = function(e) {
      warning("UCSCXenaTools <1.4.4, this shiny has a known issue (the download button cannot be used) to work with it. Please update this package!", immediate. = TRUE)
    })
  }
}

message("Dependency installation complete!")
