FROM ubuntu:20.04

ARG USERNAME=shunk031
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    sudo \
    build-essential \
	ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME\
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

ARG BATS_VERSION=v1.3.0
ARG BATS_URL=https://github.com/bats-core/bats-core.git
ARG BATS_DIR=/home/${USERNAME}/bats-core
RUN git clone -c http.sslverify=false --depth 1 --branch ${BATS_VERSION} ${BATS_URL} ${BATS_DIR}

USER $USERNAME
WORKDIR /home/$USERNAME
