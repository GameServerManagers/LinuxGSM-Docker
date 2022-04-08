# download / build / verify dependencies
# own stage = additional deps needed which are only here used
FROM ubuntu:22.04 as dependencyStage

COPY setup/installGosu.sh \
     setup/installSupercronic.sh \
     /
RUN chmod +x installGosu.sh
RUN set -eux; \
    ./installGosu.sh 1.14; \
    ./installSupercronic.sh v0.1.12 8d3a575654a6c93524c410ae06f681a3507ca5913627fa92c7086fd140fa12ce

# create linuxgsm image
# this stage should be usable by existing developers
FROM ubuntu:20.04 as linuxgsm

ARG ARG_LGSM_VERSION="master"
ENV LGSM_VERSION="${ARG_LGSM_VERSION:?}" \
    LGSM_GAMESERVER="" \
	LGSM_USE_GAMEDIG="true" \
    LGSM_CONFIG_PATTERN_GAME="" \
    USER_ID="750" \
    GROUP_ID="750" \
    LGSM_DEBUG="false" \
    \
    USER_NAME="linuxgsm" \
    LGSM_PATH="/home/linuxgsm" \
    LGSM_SCRIPTS="/home/linuxgsm-scripts" \
    PATH="$PATH:/home/linuxgsm-scripts/" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    TERM="xterm" \
    SUPERCRONIC_CONFIG="/home/linuxgsm-scripts/cron.config" \
    LGSM_STARTED="/home/linuxgsm/server.started" \
    LGSM_CURRENT_COMMAND="/home/linuxgsm/lgsm-cmd.currently"

COPY --from=dependencyStage \
     /usr/local/bin/gosu \
     /usr/local/bin/supercronic \
     /usr/local/bin/
COPY setup/installMinimalDependencies.sh \
     setup/setupUser.sh \
     setup/installLGSM.sh \
     setup/installGamedig.sh \
     setup/cleanImage.sh \
     setup/installDependencies.sh \
     setup/createAlias.sh \
     setup/entrypoint.sh \
     \
     commands/lgsm-cron-init \
     commands/lgsm-cron-start \
     commands/lgsm-init \
     commands/lgsm-fix-permission \
     commands/lgsm-load-config \
     commands/lgsm-tmux-attach \
     commands/lgsm-update-uid-gid \
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
ARG ARG_LGSM_GAMESERVER=""
ENV LGSM_GAMESERVER="${ARG_LGSM_GAMESERVER:? To build the container by hand you need to set build argument ARG_LGSM_GAMESERVER to your desired servercode}"
RUN set -eux; \
    installDependencies.sh "$LGSM_GAMESERVER"; \
    createAlias.sh "$LGSM_GAMESERVER"; \
    cleanImage.sh

HEALTHCHECK --start-period=3600s --interval=90s --timeout=900s --retries=3 \
    CMD [ -f "$LGSM_STARTED" ] && lgsm-monitor || exit 1

ENTRYPOINT ["./../linuxgsm-scripts/entrypoint.sh"]
