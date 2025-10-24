#!/bin/bash

# Bannière d'accueil
cat << 'EOF'
╔═══════════════════════════════════════╗
║       🚀 NEXUS DEV ENVIRONMENT       ║
╚═══════════════════════════════════════╝

Répertoire: /workspace (mappé à ~/projects)

Commandes utiles:
  ls          - Liste les fichiers
  cd          - Change de dossier
  git clone   - Clone un projet
  exit        - Quitte (Ctrl+D)

EOF

# Lance bash interactif
exec /bin/bash