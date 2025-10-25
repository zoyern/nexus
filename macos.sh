#!/bin/bash
# Nexus - Quick Launch macOS
set -euo pipefail
IFS=$'\n\t'

IMG="nexus_dev"
BASE_DIR="$(pwd)/nexus"
PROJECTS="$BASE_DIR/projects"

mkdir -p "$BASE_DIR"

echo "Downloading Dockerfile and startup script..."
curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/nexus/Dockerfile -o "$BASE_DIR/Dockerfile"
curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/nexus/startup.sh -o "$BASE_DIR/startup.sh"
chmod +x "$BASE_DIR/startup.sh"

echo "Building Docker environment..."
docker build -t "$IMG" "$BASE_DIR"

echo "=== Launching Nexus Terminal ==="
mkdir -p "$PROJECTS"
docker run -it --rm --name nexus_terminal -v "$PROJECTS:/workspace" "$IMG"

rm -rf "$PROJECTS"
echo "[projects/ deleted ✅]"
