#!/bin/bash
# Configuration
IMG="nexus_dev" DIR="$HOME/.nexus"
G="\033[0;32m" Y="\033[1;33m" NC="\033[0m"

# Vérifie Docker
mkdir -p "$DIR"
if ! command -v docker &>/dev/null; then
    echo "false" > "$DIR/.state"
    echo -e "${Y}Installation de Docker...${NC}"
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
else
    echo "true" > "$DIR/.state"
fi

# Télécharge les fichiers
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
    [[ $(cat "$DIR/.state") == "false" ]] && echo "Docker installé par ce script. Pour supprimer: sudo apt purge docker-ce"
    rm -rf "$DIR"
    echo -e "${G}Nettoyé${NC}"
fi