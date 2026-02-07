# Shiny App Portal

```sh
docker compose up -d
# shut down
# docker compose down
```

## 文件说明

- `dependencies.R` - 依赖配置文件，在这里添加你需要的 R 包
- `init.sh` - 初始化脚本（在容器启动时运行）

## 如何添加依赖

### 1. CRAN 包

编辑 `dependencies.R`，在 `cran_packages` 向量中添加包名：

> <https://rocker-project.org/images/versioned/shiny.html> 默认使用 shiny-verse 基础镜像，已经安装了很多基础依赖包。

```r
cran_packages <- c(
  "ggplot2",
  "dplyr",
  "lubridate"
)
```

### 2. GitHub 包

编辑 `dependencies.R`，在 `github_packages` 向量中添加包（格式：`username/repo`）：

```r
github_packages <- c(
  "tidyverse/ggplot2",
  "rstudio/shiny"
)
```

### 3. Bioconductor 包

编辑 `dependencies.R`，在 `bioconductor_packages` 向量中添加包名：

```r
bioconductor_packages <- c(
  "Biobase",
  "limma"
)
```

## 如何运行安装

### 方法 1：手动运行（推荐用于测试）

```bash
docker compose exec shiny-server Rscript /scripts/dependencies.R
```

### 方法 2：重启容器（会自动运行）

修改 `docker-compose.yml` 添加入口点：

```yaml
services:
  shiny-server:
    image: rocker/shiny-verse:latest
    # ... 其他配置 ...
    command: ["/scripts/init.sh", "/init"]
```

然后重启：

```bash
docker compose down && docker compose up -d
```

## 特点

- ✅ 自动跳过已安装的包
- ✅ 支持 CRAN、GitHub、Bioconductor 三种来源
- ✅ 包安装到 `/usr/local/lib/R/extra-library`（持久化到本地 r-libs 目录）
- ✅ 每次启动只安装缺失的包，节省时间
