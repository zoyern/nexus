# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color

# ============================
# BASE SYSTEM
# ============================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tools
    curl \
    wget \
    git \
    nano \
    vim \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    # Utilities
    ca-certificates \
    software-properties-common \
    apt-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ============================
# GIT CONFIGURATION
# ============================
RUN git config --global credential.helper store \
    && git config --global user.email "nexus@local" \
    && git config --global user.name "Nexus Dev" \
    && git config --global init.defaultBranch main \
    && git config --global pull.rebase false

# ============================
# USER SETUP
# ============================
RUN useradd -m -s /bin/bash -u 1000 dev \
    && mkdir -p /workspace/projects \
    && chown -R dev:dev /workspace

USER dev
WORKDIR /workspace

# Shell configuration
RUN echo 'export PS1="\[\e[1;32m\]nexus\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "' >> ~/.bashrc \
    && echo 'export TERM=xterm-256color' >> ~/.bashrc \
    && echo 'alias ll="ls -lah"' >> ~/.bashrc

# Startup script
COPY --chown=dev:dev startup.sh /home/dev/startup.sh
RUN chmod +x /home/dev/startup.sh

CMD ["/home/dev/startup.sh"]
