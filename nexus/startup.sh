#!/bin/bash
# Nexus - Startup script pour terminal vitrine

set -euo pipefail
IFS=$'\n\t'

PROJECTS_DIR="$(pwd)/projects"
mkdir -p "$PROJECTS_DIR"

# ===========================
# Tableau des projets
# ===========================
# Chaque projet : "Nom|Lien GitHub|Description"
PROJECTS=(
    "42_school|https://github.com/Alexis42/42_school|Exercices et projets de 42"
)

# ===========================
# Fonction pour afficher le menu
# ===========================
show_menu() {
    clear
    echo "╔═══════════════════════════════════════╗"
    echo "║       🚀 NEXUS DEV ENVIRONMENT       ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
    echo "Répertoire projets: $PROJECTS_DIR"
    echo ""
    echo "Choisissez un projet à lancer :"
    for i in "${!PROJECTS[@]}"; do
        IFS="|" read -r name _ desc <<< "${PROJECTS[$i]}"
        printf "  %d) %s - %s\n" "$((i+1))" "$name" "$desc"
    done
    echo "  0) Quitter"
}

# ===========================
# Boucle principale
# ===========================
while true; do
    show_menu
    read -rp "Votre choix: " CHOICE

    if [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
        if [ "$CHOICE" -eq 0 ]; then
            echo "Au revoir !"
            break
        elif [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#PROJECTS[@]}" ]; then
            INDEX=$((CHOICE-1))
            IFS="|" read -r name gitlink desc <<< "${PROJECTS[$INDEX]}"
            PROJECT_PATH="$PROJECTS_DIR/$name"

            echo ""
            echo "=== Projet choisi : $name ==="
            echo "$desc"
            echo ""

            # Si le projet n'existe pas encore, le cloner
            if [ ! -d "$PROJECT_PATH" ]; then
                echo "Téléchargement du projet depuis GitHub..."
                git clone "$gitlink" "$PROJECT_PATH" || {
                    echo "[ERREUR] Impossible de cloner le projet."
                    continue
                }
            fi

            # Lancer les fichiers d'exécution du projet (ex: script principal)
            if [ -f "$PROJECT_PATH/run.sh" ]; then
                echo "Lancement du projet..."
                bash "$PROJECT_PATH/run.sh"
            else
                echo "Pas de script run.sh trouvé dans $PROJECT_PATH."
            fi

            echo ""
            read -rp "Appuyez sur Entrée pour revenir au menu..."
        else
            echo "Choix invalide."
        fi
    else
        echo "Entrée non valide."
    fi
done
