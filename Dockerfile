#
# LinuxGSM Dockerfile
#
# https://github.com/GameServerManagers/LinuxGSM-Docker
#

FROM ubuntu:16.04
LABEL maintainer="LinuxGSM <me@Danielgibbs.co.uk>"

ENV DEBIAN_FRONTEND noninteractive

## Ports Use can use -p port:port also
#I open bolth tcp and udp but udp in not all time necessary.
#Line 1 commun ports steam tcp
#Line 2 commun ports steam udp
#Line 3 Rcon and Web port for some server update agent tcp
#Line 4 Rcon and Web port for some server update agent udp
EXPOSE  27015:27015 7777:7777 7778:7778 \
	27015:27015/udp 7777:7777/udp 7778:7778/udp \
	27020:27020 443:443 80:80 \
	27020:27020/udp 443:443/udp 80:80/udp

## Base System package
# install apt-utils before because some installer deb script need it
RUN dpkg --add-architecture i386 && \
	apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y --no-install-recommends apt-utils
## Tools (Optional)
#add packet you want to add here.
RUN apt-get install -y \
	nano \
	net-tools
## Dependency
RUN apt-get install -y \
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
	libgtk2.0-0:i386 \
	libdbus-glib-1-2:i386 \
	libnm-glib-dev:i386 \
	apt-transport-https \
    procps \
	locales \
	cron

ENV LINUXGSM_DOCKER_VERSION 17.11.0

## UTF-8 Problem tmux...
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

## linuxgsm.sh
RUN wget https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/master/linuxgsm.sh

## if you have a permission problem, check uid gid with the command id of the main linux user lgsm
## you need to have the same guid and uid as your real machine storage/data folder
## For example if the UID is 1001 you need to create a user for the virtual docker image with the same UID
## user config
RUN adduser --disabled-password --gecos "" --uid 1001 lgsm && \
    chown lgsm:lgsm /linuxgsm.sh && \
    chmod +x /linuxgsm.sh && \
    cp /linuxgsm.sh /home/lgsm/linuxgsm.sh && \
    usermod -G tty lgsm #solve tmux script error

USER lgsm
WORKDIR /home/lgsm

# need use xterm for LinuxGSM
ENV TERM=xterm

## Docker Details
ENV PATH=$PATH:/home/lgsm

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
