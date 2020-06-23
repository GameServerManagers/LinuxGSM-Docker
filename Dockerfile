#
# LinuxGSM Dockerfile
#
# https://github.com/GameServerManagers/LinuxGSM-Docker
#

FROM ubuntu:18.04
LABEL maintainer="LinuxGSM <me@danielgibbs.co.uk>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

## Base System
RUN apt-get update && \
    apt-get install -y software-properties-common

RUN add-apt-repository multiverse
RUN apt-get update && apt-get install -y \
    mailutils \
    postfix \
    curl \
    wget \
    file \
    tar \
    bzip2 \
    gzip \
    unzip \
    bsdmainutils \
    python \
    util-linux \
    ca-certificates \
    binutils \
    bc \
    jq \
    tmux \
    lib32gcc1 \
    libstdc++6 \
    lib32stdc++6 \
    steamcmd \
 && rm -rf /var/lib/apt/lists/*

## linuxgsm.sh
RUN wget https://linuxgsm.com/dl/linuxgsm.sh

## Add User
RUN groupadd -r linuxgsm && useradd --no-log-init -r -g linuxgsm linuxgsm
RUN	chown linuxgsm:linuxgsm /linuxgsm.sh && \
RUN	chmod +x /linuxgsm.sh && \
    cp /linuxgsm.sh /home/linuxgsm/linuxgsm.sh && \
    usermod -G tty linuxgsm && \
    chown -R linuxgsm:linuxgsm /home/linuxgsm/ && \
    chmod 755 /home/linuxgsm

USER linuxgsm
WORKDIR /home/linuxgsm
VOLUME [ "/home/linuxgsm" ]

# need use xterm for LinuxGSM
ENV TERM=xterm

## Docker Details
ENV PATH=$PATH:/home/linuxgsm

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["bash","/entrypoint.sh" ]
