#!/bin/bash

# 使用默认 Ubuntu 源（欧洲服务器）

echo "Installing system dependencies..."
apt-get update && apt-get install -y --no-install-recommends \
    cmake libgmp3-dev libmpfr-dev libglpk-dev libxml2-dev libmagick++-dev tcl tk tk-dev jags git \
    && rm -rf /var/lib/apt/lists/*

R_SCRIPT="/scripts/dependencies.R"

# 创建应用缓存目录并设置权限（shiny 用户可写）
echo "Creating app cache directories..."
mkdir -p /srv/shiny-server/TCCIA/app_cache
chown -R shiny:shiny /srv/shiny-server/TCCIA/app_cache
# 其他需要缓存的应用也可在此添加

if [ -f "$R_SCRIPT" ]; then
    echo "Running dependency installation script as root..."
    # Fix library permissions before install
    chmod -R 777 /usr/local/lib/R/extra-library 2>/dev/null || true
    chmod -R 777 /usr/local/lib/R/renv-libs 2>/dev/null || true
    Rscript "$R_SCRIPT"
else
    echo "Dependency script $R_SCRIPT not found, skipping."
fi

exec "$@"
