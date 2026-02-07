#!/bin/bash

# 配置 Ubuntu 中国镜像源
echo "Configuring Ubuntu China mirror..."

# 使用 sed 替换所有源文件中的 URL
sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' /etc/apt/sources.list
sed -i 's|http://security.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' /etc/apt/sources.list

# 同时处理 sources.list.d 目录下的文件
if [ -d "/etc/apt/sources.list.d" ]; then
    for file in /etc/apt/sources.list.d/*.list; do
        if [ -f "$file" ]; then
            sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' "$file"
            sed -i 's|http://security.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' "$file"
        fi
    done
fi

echo "Installing system dependencies..."
apt-get update && apt-get install -y --no-install-recommends \
    cmake libgmp3-dev libmpfr-dev jags \
    && rm -rf /var/lib/apt/lists/*

R_SCRIPT="/scripts/dependencies.R"

if [ -f "$R_SCRIPT" ]; then
    echo "Running dependency installation script..."
    Rscript "$R_SCRIPT"
else
    echo "Dependency script $R_SCRIPT not found, skipping."
fi

exec "$@"
