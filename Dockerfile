# download / build / verify dependencies
# own stage = additional deps needed which are only here used
FROM ubuntu:21.04 as dependencyStage

COPY scripts/installGosu.sh \
     scripts/installSupercron.sh \
     /
RUN set -eux; \
    ./installGosu.sh 1.14

# create linuxgsm image
# this stage should be usable by existing developers
FROM ubuntu:21.04 as linuxgsm

ARG LGSM_VERSION="master"
ENV LGSM_VERSION="$LGSM_VERSION" \
    LGSM_GAMESERVER="" \
    USER_ID="750" \
    GROUP_ID="750" \
    \
    USER_NAME="linuxgsm" \
    LGSM_PATH="/home/linuxgsm" \
    LGSM_SCRIPTS="/home/linuxgsm-scripts" \
    PATH="$PATH:/home/linuxgsm-scripts/" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    TERM="xterm" 

COPY --from=dependencyStage \
     /usr/local/bin/gosu \
     /usr/local/bin/
COPY scripts/installMinimalDependencies.sh \
     scripts/setupUser.sh \
     scripts/installLGSM.sh \
     scripts/installGamedig.sh \
     scripts/cleanImage.sh \
     scripts/installDependencies.sh \
     scripts/createAlias.sh \
     \
     scripts/entrypoint.sh \
     scripts/lgsm-update-uid-gid \
     scripts/lgsm-fix-permission \
     scripts/lgsm-init \
     scripts/lgsm-tmux-attach \
     "$LGSM_SCRIPTS"/

RUN set -eux; \
    installMinimalDependencies.sh; \
    setupUser.sh; \
    installLGSM.sh; \
    installGamedig.sh; \
    cleanImage.sh

VOLUME "$LGSM_PATH"
WORKDIR "$LGSM_PATH"

# install server specific dependencies
FROM linuxgsm as specific
ARG LGSM_GAMESERVER=""
ENV LGSM_GAMESERVER="$LGSM_GAMESERVER"
RUN set -eux; \
    installDependencies.sh "$LGSM_GAMESERVER"; \
    createAlias.sh "$LGSM_GAMESERVER"; \
    cleanImage.sh

ENTRYPOINT ["./../linuxgsm-scripts/entrypoint.sh"]
