From ubuntu:latest

ENV LANG en_US.UTF-8
ENV TERM screen-256color

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    sudo \
    git \
    fontconfig \
    language-pack-en \
    python

ARG EXEC_USER=shunk031
RUN useradd --create-home ${EXEC_USER}
USER ${EXEC_USER}

WORKDIR /home/${EXEC_USER}
