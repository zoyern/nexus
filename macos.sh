#!/bin/bash
# Nexus - Quick Launch (macOS)
set -euo pipefail
IFS=$'\n\t'

IMG="nexus_dev"
BASE_DIR="$(pwd)/nexus"
PROJECTS="$BASE_DIR/projects"
FORCE_DOWNLOAD=false

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "[Docker missing] Docker is required."
        echo "Install Docker Desktop: https://docs.docker.com/desktop/release-notes/"
        read -p "Press Enter after installation..."
        exit 1
    fi

    COUNT=0
    while ! docker info &>/dev/null; do
        if [ $COUNT -eq 0 ]; then
            echo "[Docker not running] Please start Docker Desktop..."
        fi
        COUNT=$((COUNT+1))
        if [ $COUNT -gt 30 ]; then
            echo "[ERROR] Docker Desktop did not start in 30 seconds."
            exit 1
        fi
        sleep 2
    done
    echo "[Docker OK]"
}

setup_dir() {
    echo "Creating Nexus folder..."
    mkdir -p "$BASE_DIR"

    if [[ "$FORCE_DOWNLOAD" = true || ! -f "$BASE_DIR/Dockerfile" || ! -f "$BASE_DIR/startup.sh" ]]; then
        echo "Downloading Dockerfile and startup.sh..."
        curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/assets/Dockerfile -o "$BASE_DIR/Dockerfile"
        curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/assets/startup.sh -o "$BASE_DIR/startup.sh"
        chmod +x "$BASE_DIR/startup.sh"
    else
        echo "Dockerfile and startup.sh already exist, skipping download."
    fi
}

build_image() {
    echo "Building Docker image..."
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
    echo "The 'projects/' folder will always be deleted."
    if [ -d "$PROJECTS" ]; then
        rm -rf "$PROJECTS"
        echo "[projects/ deleted ✅]"
    fi

    read -rp "Delete the rest of Nexus folder and Docker image? [y/N]: " RESPONSE
    RESPONSE=${RESPONSE:-N}

    if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
        echo "Saving Docker image..."
        docker save -o "$BASE_DIR/$IMG.tar" "$IMG"
        docker rmi "$IMG" 2>/dev/null || true
        rm -rf "$BASE_DIR"
        echo "[Nexus cleaned ✅]"
    else
        echo "Docker image is preserved at $BASE_DIR/$IMG.tar"
    fi
}

### MAIN
echo "=== Nexus Quick Launch (macOS) ==="
check_docker
setup_dir
build_image
run_nexus
cleanup_prompt
