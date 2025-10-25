#!/bin/bash
# Nexus - Quick setup (Linux / WSL / macOS)
set -euo pipefail

IMG="nexus_dev"
BASE_DIR="$(pwd)/nexus"
PROJECTS="$BASE_DIR/projects"
MAX_WAIT=60
DOCKER_STARTED=false

### ===========================
### UTILITIES
### ===========================

print_section() { echo -e "\n\033[1;34m▶\033[0m \033[1m$1\033[0m"; }
print_ok()      { echo -e "  \033[32m✓\033[0m $1"; }
print_warn()    { echo -e "  \033[33m⚠\033[0m $1"; }
print_error()   { echo -e "  \033[31m✗\033[0m $1" >&2; }

die() {
    print_error "$1"
    exit "${2:-1}"
}

detect_os() {
    case "$(uname -s)" in
        Linux*)
            grep -qi microsoft /proc/version 2>/dev/null && echo "WSL" || echo "Linux"
            ;;
        Darwin*) echo "Mac" ;;
        *) echo "Unknown" ;;
    esac
}

get_hash() {
    if command -v md5sum &>/dev/null; then
        md5sum "$1" 2>/dev/null | cut -d' ' -f1
    else
        md5 -q "$1" 2>/dev/null
    fi
}

### ===========================
### CHECKS
### ===========================

check_docker() {
    print_section "Docker"
    
    command -v docker &>/dev/null || {
        print_error "Docker not installed"
        case "$OS" in
            WSL)   echo "  → Install Docker Desktop + enable WSL integration" ;;
            Mac)   echo "  → Install Docker Desktop: https://docker.com/get-started" ;;
            Linux) echo "  → Install Docker Engine: https://docs.docker.com/engine/install/" ;;
        esac
        exit 1
    }
    
    # Try starting Docker if not running
    if ! docker info &>/dev/null; then
        DOCKER_STARTED=true
        print_warn "Docker not running, starting..."
        
        case "$OS" in
            Linux)
                sudo systemctl start docker || die "Failed to start Docker" 1
                ;;
            Mac)
                open -a Docker
                ;;
            WSL)
                powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" 2>/dev/null || true
                ;;
        esac
        
        # Wait for Docker to be ready
        echo -n "  Waiting for Docker"
        local count=0
        until docker info &>/dev/null; do
            sleep 2
            count=$((count + 2))
            echo -n "."
            if [ $count -ge $MAX_WAIT ]; then
                echo ""
                die "Docker did not start within ${MAX_WAIT}s" 1
            fi
        done
        echo ""
    fi
    
    print_ok "Running on $OS"
}

### ===========================
### SETUP
### ===========================

setup_files() {
    print_section "Files"
    mkdir -p "$BASE_DIR"
    
    # Skip if files already exist
    if [[ -f "$BASE_DIR/Dockerfile" && -f "$BASE_DIR/startup.sh" ]]; then
        print_ok "Already present"
        return 0
    fi
    
    # Download from GitHub
    curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/nexus/Dockerfile \
        -o "$BASE_DIR/Dockerfile" || die "Failed to download Dockerfile"
    curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/nexus/startup.sh \
        -o "$BASE_DIR/startup.sh" || die "Failed to download startup.sh"
    chmod +x "$BASE_DIR/startup.sh"
    print_ok "Downloaded from GitHub"
}

build_image() {
    print_section "Building image"
    
    # Check if rebuild needed
    if docker image inspect "$IMG" &>/dev/null; then
        local dockerfile_hash=$(get_hash "$BASE_DIR/Dockerfile")
        local image_label=$(docker image inspect "$IMG" --format='{{index .Config.Labels "dockerfile.hash"}}' 2>/dev/null || echo "")
        
        if [[ "$dockerfile_hash" == "$image_label" ]]; then
            print_ok "Image up-to-date"
            return 0
        fi
    fi
    
    # Build with loading animation
    echo -n "  Building"
    docker build -q \
        --label "dockerfile.hash=$(get_hash "$BASE_DIR/Dockerfile")" \
        --label "build.timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        -t "$IMG" "$BASE_DIR" 2>&1 | grep -v "DEPRECATED" | grep -v "buildx" > /dev/null &
    
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r  \033[36m${spin:$i:1}\033[0m Building image..."
        sleep 0.1
    done
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        printf "\r  \033[32m✓\033[0m Built successfully       \n"
    else
        printf "\r  \033[31m✗\033[0m Build failed            \n"
        die "Docker build failed" $exit_code
    fi
}

### ===========================
### RUN
### ===========================

run_container() {
    print_section "Launching Nexus"
    mkdir -p "$PROJECTS"
    
    docker run -it --rm \
        --name nexus_terminal \
        -v "$PROJECTS:/workspace/projects" \
        -e "HOST_OS=$OS" \
        "$IMG"
}

### ===========================
### CLEANUP
### ===========================

cleanup() {
    print_section "Cleanup"
    
    # Always remove projects
    [[ -d "$PROJECTS" ]] && rm -rf "$PROJECTS"
    print_ok "Projects removed"
    
    # Always remove Docker image
    docker rmi "$IMG" &>/dev/null && print_ok "Image removed" || true
    
    # Close Docker if we started it
    if [ "$DOCKER_STARTED" = true ]; then
        print_warn "Closing Docker..."
        case "$OS" in
            Mac)
                pkill -f Docker 2>/dev/null || true
                ;;
            WSL)
                powershell.exe -Command "Stop-Process -Name 'Docker Desktop' -Force" 2>/dev/null || true
                ;;
        esac
        print_ok "Docker closed"
    fi
    
    # Ask only for Nexus folder (Dockerfile + startup.sh)
    read -rp "  Remove Nexus configuration files? [y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        rm -rf "$BASE_DIR"
        print_ok "Configuration removed"
    else
        print_warn "Configuration kept in $BASE_DIR"
    fi
}

### ===========================
### MAIN
### ===========================

main() {
    echo -e "\n\033[1;36m╔════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║\033[0m  \033[1mNEXUS DEV ENVIRONMENT\033[0m         \033[1;36m║\033[0m"
    echo -e "\033[1;36m╚════════════════════════════════╝\033[0m"
    
    OS=$(detect_os)
    
    check_docker
    setup_files
    build_image
    run_container
    cleanup
}

main "$@"
