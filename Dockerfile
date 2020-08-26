#
# LinuxGSM Dockerfile
#
# https://github.com/GameServerManagers/LinuxGSM-Docker
#

FROM ubuntu:18.04
LABEL maintainer="LinuxGSM <me@danielgibbs.co.uk>"

ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y locales apt-utils debconf-utils \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    ENV LANG en_US.utf8

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
    && steamcmd +quit \

# Install Gamedig https://docs.linuxgsm.com/requirements/gamedig
    && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g gamedig \
    
    # Cleanup
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

## linuxgsm.sh
RUN wget -O linuxgsm.sh https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/feature/docker/linuxgsm.sh

# Add the linuxgsm user
RUN adduser \
    --disabled-login \
    --disabled-password \
    --shell /bin/bash \
    --gecos "" \
    linuxgsm \
    && usermod -G tty linuxgsm \
    && chown -R linuxgsm:linuxgsm /home/linuxgsm \
    && chmod +x linuxgsm.sh

# Switch to the user linuxgsm
USER linuxgsm

WORKDIR /home/linuxgsm
VOLUME [ "/home/linuxgsm" ]

# need use xterm for LinuxGSM
ENV TERM=xterm

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh" ]
