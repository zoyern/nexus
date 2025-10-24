# Image de base Ubuntu minimale
FROM ubuntu:22.04

# Évite les prompts interactifs
ENV DEBIAN_FRONTEND=noninteractive

# DÉPENDANCES DE BASE
# Ajoutez vos dépendances au fur et à mesure ici
RUN apt-get update && apt-get install -y \
    # Outils essentiels
    curl \
    git \
    # Éditeur
    nano \
    && rm -rf /var/lib/apt/lists/*

# DÉPENDANCES PROJETS
# Décommentez selon vos besoins:

# Python
# RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*

# Node.js
# RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*

# Compilation C/C++
# RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

# Rust
# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Go
# RUN apt-get update && apt-get install -y golang && rm -rf /var/lib/apt/lists/*

# Utilisateur non-root
RUN useradd -m -s /bin/bash dev
USER dev
WORKDIR /workspace

# Script de démarrage
COPY startup.sh /home/dev/startup.sh
RUN sudo chmod +x /home/dev/startup.sh

# Terminal coloré
RUN echo 'export PS1="\[\e[1;32m\]nexus\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]$ "' >> ~/.bashrc

CMD ["/home/dev/startup.sh"]