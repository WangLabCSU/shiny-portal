#!/bin/bash

# 配置 Ubuntu 中国镜像源
echo "Configuring Ubuntu China mirror..."

# 直接覆盖 sources.list 为阿里云镜像
cat > /etc/apt/sources.list << 'EOF'
deb http://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
EOF

# 清空 sources.list.d 目录（防止其他源覆盖）
rm -f /etc/apt/sources.list.d/*.list

# 强制清理 apt 缓存，确保使用新配置
rm -rf /var/lib/apt/lists/*

# 显示当前源配置
echo "Current apt sources:"
cat /etc/apt/sources.list

echo "Installing system dependencies..."
apt-get update && apt-get install -y --no-install-recommends \
    cmake libgmp3-dev libmpfr-dev jags git \
    && rm -rf /var/lib/apt/lists/*

R_SCRIPT="/scripts/dependencies.R"

if [ -f "$R_SCRIPT" ]; then
    echo "Running dependency installation script..."
    Rscript "$R_SCRIPT"
else
    echo "Dependency script $R_SCRIPT not found, skipping."
fi

exec "$@"
