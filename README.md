# Shiny Portal

一个基于 Docker 的 Shiny Server 环境，支持自动化的依赖管理。

## 特点

- 使用 `rocker/shiny-verse` 作为基础镜像，预装常用 R 包
- 自动化依赖安装（支持 CRAN、GitHub、Bioconductor）
- R 包持久化到本地目录
- 以 shiny 用户运行应用，更安全

## 快速开始

### 前置要求

- Docker
- Docker Compose

### 启动服务

```bash
docker compose up -d
```

### 访问 Shiny Server

打开浏览器访问：http://localhost:3838

## 项目结构

```
shiny-portal/
├── apps/              # Shiny 应用目录
├── conf/              # Shiny Server 配置
├── logs/              # 日志目录
├── r-libs/            # 持久化的 R 包
├── scripts/           # 初始化和依赖管理脚本
│   ├── dependencies.R # 依赖配置文件
│   ├── init.sh        # 初始化脚本
│   └── README.md      # 详细使用说明
└── docker-compose.yml # Docker Compose 配置
```

## 如何添加依赖

编辑 `scripts/dependencies.R` 文件：

```r
# CRAN 包
cran_packages <- c(
  "ggplot2",
  "dplyr"
)

# GitHub 包 (格式: username/repo)
github_packages <- c(
  "tidyverse/ggplot2"
)

# Bioconductor 包
bioconductor_packages <- c(
  "Biobase"
)
```

添加后重启容器：

```bash
docker compose down && docker compose up -d
```

## 更多文档

详细的使用说明请参考：[scripts/README.md](scripts/README.md)

## License

MIT
