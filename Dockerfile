ARG BASE_IMAGE=ubuntu:22.04

# ========================================
#  Base environment
# ========================================

FROM ${BASE_IMAGE} as base

# Avoid the following error:
# curl: (77) error setting certificate file: /etc/ssl/certs/ca-certificates.crt
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates

# Install minimum requirements
RUN apt-get install -y --no-install-recommends \
    sudo \
    git \
    wget \
    curl

# Create user
ARG USERNAME=shunk031
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -G sudo -s /bin/bash \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo 'Defaults verifypw = any' >> /etc/sudoers
USER ${USERNAME}

WORKDIR /home/${USERNAME}

# ========================================
#  Development environment
# ========================================

FROM base as dev

# Install chezmoi
RUN sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Install requirements for testing
RUN sudo apt-get install -y --no-install-recommends \
    bats \
    kcov

WORKDIR /home/${USERNAME}/.local/share/chezmoi
