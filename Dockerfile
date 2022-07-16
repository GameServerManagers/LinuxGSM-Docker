# download / build / verify dependencies
# own stage = additional deps needed which are only here used
FROM ubuntu:22.04 as dependencyStage

COPY setup/installGosu.sh \
     setup/installOpenSSL_1.1n.sh \
     setup/installSupercronic.sh \
     /
RUN chmod +x installGosu.sh
RUN set -eux; \
    ./installGosu.sh 1.14; \
    ./installSupercronic.sh v0.2.1 5eb5e2533fe75acffa63e437c0d8c4cb1f0c96891b84ae10ef4e53d602505f60; \
    ./installOpenSSL_1.1n.sh

# create linuxgsm image
# this stage should be usable by existing developers
FROM ubuntu:22.04 as linuxgsm

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
COPY --from=dependencyStage \
     /usr/local/lib \
     /usr/local/lib/
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
