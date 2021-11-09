FROM ubuntu:18.04 as dependencyStage

ENV GOSU_VERSION 1.14
COPY scripts/installGosu.sh /
RUN set -eux; \
    ./installGosu.sh

FROM ubuntu:18.04

LABEL maintainer="LinuxGSM <me@danielgibbs.co.uk>"

COPY scripts/cleanImage.sh \
     scripts/entrypoint.sh \
     scripts/installLGSM.sh \
     scripts/installMinimalDependencies.sh \
     scripts/setupUser.sh \
     /home/
COPY --from=dependencyStage /usr/local/bin/gosu /usr/local/bin/gosu

## changable
ARG LGSM_VERSION="v21.4.1"
ENV LGSM_VERSION="$LGSM_VERSION" \
    USER_ID="750" \
    GROUP_ID="750"

## internal, dont change
ENV USER_NAME="linuxgsm" \
    LGSM_PATH="/home/linuxgsm" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    TERM="xterm" \
    PATH="$PATH:/home/linuxgsm"

RUN set -eux; \
cd /home/; \
./installMinimalDependencies.sh; \
./setupUser.sh; \
./installLGSM.sh; \
./cleanImage.sh

VOLUME "$LGSM_PATH"
WORKDIR "$LGSM_PATH"
ENTRYPOINT ["bash","../entrypoint.sh" ]
