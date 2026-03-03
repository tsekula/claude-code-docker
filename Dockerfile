FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages
RUN apt-get update && apt-get install -y \
    tmux \
    curl \
    git \
    ca-certificates \
    locales \
    nano \
    procps \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Remove the default ubuntu user (UID 1000) and create claude at UID 1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u 1000 -s /bin/bash claude \
    && echo 'claude ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install Claude Code via native installer, then move binary to system path
# so it isn't hidden by the named volume mounted over /home/claude at runtime
USER claude
RUN curl -fsSL https://claude.ai/install.sh | bash
USER root
RUN cp -L /home/claude/.local/bin/claude /usr/local/bin/claude \
    && rm -rf /home/claude/.local

# Seed .bashrc to source secrets and add claude binary to PATH
RUN echo '\n# Source API keys if available\n[ -f "$HOME/.env_secrets" ] && source "$HOME/.env_secrets"' \
    >> /home/claude/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
