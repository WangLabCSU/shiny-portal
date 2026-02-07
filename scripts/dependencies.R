cran_packages <- c(
)

github_packages <- c(
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
  for (pkg in github_packages) {
    pkg_name <- sub(".*/", "", sub("#.*", "", sub("@.*", "", pkg)))
    if (!pkg_name %in% rownames(installed.packages(lib.loc = install_path))) {
      message(sprintf("Installing GitHub package: %s", pkg))
      install_github(pkg, lib = install_path)
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

message("Dependency installation complete!")
