#!/bin/bash
# Nexus - Lancement rapide Linux / WSL2
set -euo pipefail
IFS=$'\n\t'

### ===========================
### CONFIGURATION
### ===========================
IMG="nexus_dev"              # Nom de l'image Docker
DIR="$HOME/.nexus"           # Dossier temporaire
PROJECTS="$HOME/projects"    # Dossier projets
MAX_WAIT=60                  # Temps max pour attendre Docker Desktop en secondes

### ===========================
### FONCTIONS
### ===========================
check_docker() {
    # Vérifie si la commande docker existe
    if ! command -v docker &>/dev/null; then
        echo "[Docker absent] Docker Desktop est obligatoire sur WSL2."
        echo "Téléchargez-le ici : https://docs.docker.com/desktop/release-notes/"
        echo "Activez WSL2 Integration dans Settings > Resources > WSL Integration"
        read -p "Appuyez sur Entrée après installation pour relancer ce script..."
        exit 1
    fi

    # Vérifie si Docker Desktop tourne
    COUNT=0
    while ! docker info &>/dev/null; do
        if [ $COUNT -eq 0 ]; then
            echo "[Docker non actif] Tentative d'ouverture automatique de Docker Desktop..."
            powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
        fi
        COUNT=$((COUNT+1))
        if [ $COUNT -gt $MAX_WAIT ]; then
            echo "[ERREUR] Docker Desktop n'a pas démarré dans $MAX_WAIT secondes."
            echo "Vérifiez que WSL2 Integration est activée pour cette distro."
            exit 1
        fi
        sleep 2
    done

    echo "[Docker OK]"
}

download_files() {
    mkdir -p "$DIR"
    echo "Téléchargement des fichiers..."
    curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/Dockerfile -o "$DIR/Dockerfile"
    curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/startup.sh -o "$DIR/startup.sh"
    chmod +x "$DIR/startup.sh"
}

build_image() {
    echo "Construction de l'environnement..."
    docker build -q -t "$IMG" "$DIR"
}

run_nexus() {
    echo "=== Lancement du terminal Nexus ==="
    docker run -it --rm --name nexus_terminal -v "$PROJECTS:/workspace" "$IMG"
}

clean_nexus() {
    echo "Nettoyage de l'environnement..."
    docker rmi "$IMG" 2>/dev/null || true
    rm -rf "$DIR"
    echo "[Nexus terminé et propre]"
}

### ===========================
### MAIN
### ===========================
echo "=== Nexus Installation rapide (Linux/WSL2) ==="

check_docker
download_files
build_image
run_nexus
clean_nexus
