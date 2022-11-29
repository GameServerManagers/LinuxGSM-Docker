#
# LinuxGSM Base Dockerfile
#
# https://github.com/GameServerManagers/LinuxGSM-Docker
#

FROM gameservermanagers/linuxgsm-docker:latest

LABEL maintainer="Rasmus Koit <rasmuskoit@gmail.com>"

COPY entrypoint.sh /home/linuxgsm/entrypoint.sh

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "bash","./entrypoint.sh" ]
