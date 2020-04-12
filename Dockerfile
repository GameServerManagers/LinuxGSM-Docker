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
RUN dpkg --add-architecture i386 && \
	apt update -y && \
	apt install -y \
		iproute2 \
		mailutils \
		postfix \
		curl \
		wget \
		file \
		bzip2 \
		gzip \
		unzip \
		bsdmainutils \
		python \
		util-linux \
		binutils \
		bc \
		jq \
		tmux \
		lib32gcc1 \
		libstdc++6 \
		libstdc++6:i386 \
		apt-transport-https \
		ca-certificates \
		telnet \
		expect \
		libncurses5:i386 \
		libcurl4-gnutls-dev:i386 \
		libstdc++5:i386 \
		netcat \
		lib32stdc++6 \		
		lib32tinfo5 \
		xz-utils \
		zlib1g:i386 \
		libldap-2.4-2:i386 \
		lib32z1 \
		default-jre \
		speex:i386 \
		libtbb2 \
		libxrandr2:i386 \
		libglu1-mesa:i386 \
		libxtst6:i386 \
		libusb-1.0-0:i386 \
		libopenal1:i386 \
		libpulse0:i386 \
		libdbus-glib-1-2:i386 \
		libnm-glib4:i386 \
		zlib1g \
		libssl1.0.0:i386 \
		libtcmalloc-minimal4:i386 \
		libsdl1.2debian \
		libnm-glib-dev:i386 \
		&& apt-get clean \
	  && rm -rf /var/lib/apt/lists/*

# Add the linuxgsm user
RUN adduser \
      --disabled-login \
      --disabled-password \
      --shell /bin/bash \
      --gecos "" \
      linuxgsm \
    && usermod -G tty linuxgsm \
    && chown -R linuxgsm:linuxgsm /home/linuxgsm

# Switch to the user linuxgsm
USER linuxgsm


## linuxgsm.sh
RUN wget https://linuxgsm.com/dl/linuxgsm.sh

## user config
RUN groupadd -g 750 -o linuxgsm && \
	adduser --uid 750 --disabled-password --gecos "" --ingroup linuxgsm linuxgsm && \
	chown linuxgsm:linuxgsm /linuxgsm.sh && \
	chmod +x /linuxgsm.sh && \
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
