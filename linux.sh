#!/bin/bash
# Nexus - Lancement rapide Linux / WSL2
set -euo pipefail
IFS=$'\n\t'

### ===========================
### CONFIGURATION
### ===========================
IMG="nexus_dev"                  # Nom de l'image Docker
BASE_DIR="$(pwd)/nexus"          # Dossier local “nexus”
PROJECTS="$BASE_DIR/projects"    # Dossier projets
MAX_WAIT=60                      # Timeout Docker Desktop
FORCE_DOWNLOAD=false             # Option future --force pour debug

### ===========================
### FONCTIONS
### ===========================
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "[Docker absent] Docker Desktop est obligatoire sur WSL2."
        echo "Téléchargez-le ici : https://docs.docker.com/desktop/release-notes/"
        echo "Activez WSL2 Integration dans Settings > Resources > WSL Integration"
        read -p "Appuyez sur Entrée après installation pour relancer ce script..."
        exit 1
    fi

    COUNT=0
    while ! docker info &>/dev/null; do
        if [ $COUNT -eq 0 ]; then
            echo "[Docker non actif] Tentative d'ouverture automatique de Docker Desktop..."
            powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
        fi
        COUNT=$((COUNT+1))
        if [ $COUNT -gt $MAX_WAIT ]; then
            echo "[ERREUR] Docker Desktop n'a pas démarré dans $MAX_WAIT secondes."
            echo "Vérifiez que WSL2 Integration est activée."
            exit 1
        fi
        sleep 2
    done

    echo "[Docker OK]"
}

setup_dir() {
    echo "Création du dossier Nexus local..."
    mkdir -p "$BASE_DIR"

    if [[ "$FORCE_DOWNLOAD" = true || ! -f "$BASE_DIR/Dockerfile" || ! -f "$BASE_DIR/startup.sh" ]]; then
        echo "Téléchargement des fichiers depuis GitHub..."
        curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/assets/Dockerfile -o "$BASE_DIR/Dockerfile"
        curl -fsSL https://raw.githubusercontent.com/zoyern/nexus/main/assets/startup.sh -o "$BASE_DIR/startup.sh"
        chmod +x "$BASE_DIR/startup.sh"
    else
        echo "Fichiers Dockerfile et startup.sh déjà présents, pas de téléchargement."
    fi
}

build_image() {
    echo "Construction de l'environnement Docker..."
    docker build -q -t "$IMG" "$BASE_DIR"
}

run_nexus() {
    echo "=== Lancement du terminal Nexus ==="
    mkdir -p "$PROJECTS"
    docker run -it --rm --name nexus_terminal -v "$PROJECTS:/workspace" "$IMG"
}

cleanup_prompt() {
    echo ""
    echo "=================== NETTOYAGE ==================="
    echo "Le dossier Nexus contient Dockerfile, startup.sh et tous les fichiers temporaires."
    echo "L'image Docker sera exportée dans $BASE_DIR/$IMG.tar pour rester dans le dossier."
    echo "-------------------------------------------------"

    # Supprime toujours projects/
    if [ -d "$PROJECTS" ]; then
        rm -rf "$PROJECTS"
        echo "[projects/ supprimé ✅]"
    fi

    read -rp "Supprimer le reste du dossier Nexus et l'image Docker ? [o/N]: " RESPONSE
    RESPONSE=${RESPONSE:-N}

    if [[ "$RESPONSE" =~ ^[Oo]$ ]]; then
        echo "Export de l'image Docker dans $BASE_DIR/$IMG.tar..."
        docker save -o "$BASE_DIR/$IMG.tar" "$IMG"
        docker rmi "$IMG" 2>/dev/null || true
        rm -rf "$BASE_DIR"  # Supprime tout y compris l'image exportée si tu veux clean complet
        echo "[Nexus nettoyé ✅]"
    else
        echo "L'image Docker est conservée et peut être retrouvée dans $BASE_DIR/$IMG.tar"
    fi
}

### ===========================
### MAIN
### ===========================
echo "=== Nexus Installation rapide (Linux/WSL2) ==="

check_docker
setup_dir
build_image
run_nexus
cleanup_prompt
