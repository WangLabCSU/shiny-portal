#!/bin/bash

# 配置 Ubuntu 中国镜像源
echo "Configuring Ubuntu China mirror..."

# 清空 sources.list.d 目录（防止其他源覆盖）
rm -f /etc/apt/sources.list.d/*.list
rm -f /etc/apt/sources.list.d/*.sources

# 删除旧的 sources.list，使用 DEB822 格式配置（Ubuntu 24.04+ 推荐）
rm -f /etc/apt/sources.list

# 创建新的 DEB822 格式源配置（Ubuntu 24.04+ 使用 .sources 文件）
cat > /etc/apt/sources.list.d/aliyun.sources << 'EOF'
Types: deb
URIs: http://mirrors.aliyun.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://mirrors.aliyun.com/ubuntu/
Suites: noble-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

# 强制清理 apt 缓存，确保使用新配置
rm -rf /var/lib/apt/lists/*

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
    echo "Running dependency installation script as shiny user..."
    # 以 shiny 用户运行，确保包权限正确
    su -s /bin/bash shiny -c "Rscript '$R_SCRIPT'"
else
    echo "Dependency script $R_SCRIPT not found, skipping."
fi

exec "$@"
