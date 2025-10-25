#!/bin/bash
# Nexus - Quick Launch Linux / WSL2
set -euo pipefail
IFS=$'\n\t'

IMG="nexus_dev"
BASE_DIR="$(pwd)/nexus"
PROJECTS="$BASE_DIR/projects"
MAX_WAIT=60

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "[Docker missing] Docker Desktop is required on WSL2."
        echo "Download here: https://docs.docker.com/desktop/release-notes/"
        echo "Enable WSL2 integration in Settings > Resources > WSL Integration"
        read -p "Press Enter after installation to rerun this script..."
        exit 1
    fi

    COUNT=0
    while ! docker info &>/dev/null; do
        if [ $COUNT -eq 0 ]; then
            echo "[Docker inactive] Attempting to start Docker Desktop..."
            powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
        fi
        COUNT=$((COUNT+1))
        if [ $COUNT -gt $MAX_WAIT ]; then
            echo "[ERROR] Docker Desktop did not start within $MAX_WAIT seconds."
            exit 1
        fi
        sleep 2
    done
    echo "[Docker OK]"
}

setup_dir() {
    echo "Creating local Nexus directory..."
    mkdir -p "$BASE_DIR"
    if [[ ! -f "$BASE_DIR/Dockerfile" || ! -f "$BASE_DIR/startup.sh" ]]; then
        echo "Downloading Dockerfile and startup script..."
        curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/nexus/Dockerfile -o "$BASE_DIR/Dockerfile"
        curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/nexus/startup.sh -o "$BASE_DIR/startup.sh"
        chmod +x "$BASE_DIR/startup.sh"
    else
        echo "Dockerfile and startup.sh already exist, skipping download."
    fi
}

build_image() {
    echo "Building Docker environment..."
    docker build -q -t "$IMG" "$BASE_DIR"
}

run_nexus() {
    echo "=== Launching Nexus Terminal ==="
    mkdir -p "$PROJECTS"
    docker run -it --rm --name nexus_terminal -v "$PROJECTS:/workspace" "$IMG"
}

cleanup_prompt() {
    echo ""
    echo "=================== CLEANUP ==================="
    echo "The Nexus directory contains Dockerfile, startup.sh, and temporary files."
    echo "Docker image can be exported to $BASE_DIR/$IMG.tar"
    echo "-------------------------------------------------"

    if [ -d "$PROJECTS" ]; then
        rm -rf "$PROJECTS"
        echo "[projects/ deleted ✅]"
    fi

    read -rp "Delete the rest of the Nexus directory and Docker image? [y/N]: " RESPONSE
    RESPONSE=${RESPONSE:-N}

    if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
        echo "Exporting Docker image to $BASE_DIR/$IMG.tar..."
        docker save -o "$BASE_DIR/$IMG.tar" "$IMG"
        docker rmi "$IMG" 2>/dev/null || true
        rm -rf "$BASE_DIR"
        echo "[Nexus cleaned ✅]"
    else
        echo "Docker image preserved in $BASE_DIR/$IMG.tar"
    fi
}

echo "=== Nexus Quick Install (Linux/WSL2) ==="
check_docker
setup_dir
build_image
run_nexus
cleanup_prompt
