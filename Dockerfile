#
# LinuxGSM Dockerfile
#
# https://github.com/GameServerManagers/LinuxGSM-Docker
#

FROM ubuntu:20.04

LABEL maintainer="LinuxGSM <me@danielgibbs.co.uk>"

ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -ex; \
apt-get update; \
apt-get install -y locales; \
rm -rf /var/lib/apt/lists/*; \
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN apt-get update \
    && apt-get install -y locales apt-utils debconf-utils
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

## Base System
RUN apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository multiverse \
    && apt-get update \
    && apt-get install -y \
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
    netcat \
    lib32gcc1 \
    lib32stdc++6 \
    iproute2 \
    nano \
    iputils-ping \

    # Install SteamCMD
    && echo steam steam/question select "I AGREE" | debconf-set-selections \
    && echo steam steam/license note '' | debconf-set-selections \
    && dpkg --add-architecture i386 \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends ca-certificates locales steamcmd \
    && mkdir -p "/home/linuxgsm/.local/share/Steam" \
    && mkdir -p "/home/linuxgsm/.steam" \
    && ln -s "/home/linuxgsm/.local/share/Steam" "/home/linuxgsm/.steam/root" \
    && ln -s "/home/linuxgsm/.local/share/Steam" "/home/linuxgsm/.steam/steam" \
    && ln -s /usr/games/steamcmd /usr/local/bin/steamcmd \

    # Install Gamedig https://docs.linuxgsm.com/requirements/gamedig
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g gamedig \

    # Cleanup
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

## linuxgsm.sh
RUN set -ex; \
wget https://linuxgsm.com/dl/linuxgsm.sh

## user config
RUN set -ex; \
groupadd -g 750 -o linuxgsm; \
adduser --uid 750 --disabled-password --gecos "" --ingroup linuxgsm linuxgsm; \
chown linuxgsm:linuxgsm /linuxgsm.sh; \
chmod +x /linuxgsm.sh; \
cp /linuxgsm.sh /home/linuxgsm/linuxgsm.sh; \
usermod -G tty linuxgsm; \
chown -R linuxgsm:linuxgsm /home/linuxgsm/; \
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
