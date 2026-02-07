#!/bin/bash

echo "Installing system dependencies..."
apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    && rm -rf /var/lib/apt/lists/*

R_SCRIPT="/scripts/dependencies.R"

if [ -f "$R_SCRIPT" ]; then
    echo "Running dependency installation script..."
    Rscript "$R_SCRIPT"
else
    echo "Dependency script $R_SCRIPT not found, skipping."
fi

exec "$@"
