#!/bin/bash

# 配置 Ubuntu 中国镜像源
echo "Configuring Ubuntu China mirror..."
cat > /etc/apt/sources.list << 'EOF'
deb http://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
EOF

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
