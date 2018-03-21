#
# LinuxGSM Dockerfile
#
# https://github.com/GameServerManagers/LinuxGSM-Docker
#

FROM ubuntu:16.04
LABEL maintainer="LinuxGSM <me@Danielgibbs.co.uk>"

ENV DEBIAN_FRONTEND noninteractive

## Base System
RUN dpkg --add-architecture i386 && \
	apt-get update -y && \
	apt-get install -y \
		binutils \
		mailutils \
		postfix \
		bc \
		curl \
		wget \
		file \
		bzip2 \
		gzip \
		unzip \
		xz-utils \
		libmariadb2 \
		bsdmainutils \
		python \
		util-linux \
		ca-certificates \
		tmux \
		lib32gcc1 \
		libstdc++6 \
		libstdc++6:i386 \
		libstdc++5:i386 \
		libsdl1.2debian \
		default-jdk \
		lib32tinfo5 \
		speex:i386 \
		libtbb2 \
		libcurl4-gnutls-dev:i386 \
		libtcmalloc-minimal4:i386 \
		libncurses5:i386 \
		zlib1g:i386 \
		libldap-2.4-2:i386 \
		libxrandr2:i386 \
		libglu1-mesa:i386 \
		libxtst6:i386 \
		libusb-1.0-0-dev:i386 \
		libxxf86vm1:i386 \
		libopenal1:i386 \
		libssl1.0.0:i386 \
		libgtk2.0-0:i386 \
		libdbus-glib-1-2:i386 \
		libnm-glib-dev:i386

## lgsm.sh
RUN wget https://gameservermanagers.com/dl/linuxgsm.sh

## user config
RUN adduser --disabled-password --gecos "" lgsm && \
	chown lgsm:lgsm /linuxgsm.sh && \
	chmod +x /linuxgsm.sh && \
	cp /linuxgsm.sh /home/lgsm/linuxgsm.sh

USER lgsm
WORKDIR /home/lgsm

# need use xterm for LinuxGSM
ENV TERM=xterm

## Docker Details
ENV PATH=$PATH:/home/lgsm

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]