#!/bin/bash
# Configuration
IMG="nexus_dev" DIR="$HOME/.nexus"
G="\033[0;32m" Y="\033[1;33m" R="\033[0;31m" NC="\033[0m"

# Vérifie Docker
mkdir -p "$DIR"
if ! command -v docker &>/dev/null; then
    echo "false" > "$DIR/.state"
    echo -e "${Y}Docker requis. Installer via Homebrew ? (brew install --cask docker)${NC}"
    read -p "Oui (O/n): " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]] && command -v brew &>/dev/null; then
        brew install --cask docker
        echo -e "${G}Lancez Docker Desktop puis réexécutez ce script${NC}"
        exit 0
    else
        echo -e "${R}Installez Docker Desktop: https://docker.com/products/docker-desktop${NC}"
        exit 1
    fi
else
    echo "true" > "$DIR/.state"
fi

# Vérifie que Docker tourne
docker info &>/dev/null || { echo -e "${R}Lancez Docker Desktop${NC}"; exit 1; }

# Télécharge
echo -e "${G}Téléchargement...${NC}"
curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/Dockerfile -o "$DIR/Dockerfile"
curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/startup.sh -o "$DIR/startup.sh"

# Build et run
echo -e "${G}Construction...${NC}"
docker build -t "$IMG" "$DIR" && docker run -it --rm -v "$HOME/projects:/workspace" "$IMG"

# Nettoyage
echo -e "\n${Y}Nettoyage ?${NC}"
read -p "Supprimer l'environnement ? (o/N) " -r
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    docker rmi "$IMG" 2>/dev/null
    [[ $(cat "$DIR/.state") == "false" ]] && echo "Docker installé par ce script. Pour supprimer: brew uninstall --cask docker"
    rm -rf "$DIR"
    echo -e "${G}Nettoyé${NC}"
fi