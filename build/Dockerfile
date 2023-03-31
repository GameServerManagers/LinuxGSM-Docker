# download / build / verify dependencies
# own stage = additional deps needed which are only here used
FROM ubuntu:22.04 as dependencyStage

COPY build/installGosu.sh \
	build/installOpenSSL_1.1.sh \
	build/installSupercronic.sh \
	/
RUN chmod +x installGosu.sh
RUN set -eux; \
	./installGosu.sh 1.16; \
	./installSupercronic.sh v0.2.2 8c509ffd2f4adfb722e388cc3ad65ac0baf5e69eb472e298144f50303216903d; \
	./installOpenSSL_1.1.sh 1.1.1t

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
COPY build/installMinimalDependencies.sh \
	build/setupUser.sh \
	build/installLGSM.sh \
	build/installGamedig.sh \
	build/cleanImage.sh \
	build/installServerDependencies.sh \
	build/createAlias.sh \
	\
	runtime/entrypoint.sh \
	runtime/lgsm-cron-init \
	runtime/lgsm-cron-start \
	runtime/lgsm-init \
	runtime/lgsm-fix-permission \
	runtime/lgsm-load-config \
	runtime/lgsm-tmux-attach \
	runtime/lgsm-update-uid-gid \
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
	installServerDependencies.sh "$LGSM_GAMESERVER"; \
	createAlias.sh "$LGSM_GAMESERVER"; \
	cleanImage.sh

HEALTHCHECK --start-period=3600s --interval=90s --timeout=900s --retries=3 \
	CMD [ -f "$LGSM_STARTED" ] && lgsm-monitor || exit 1

ENTRYPOINT ["./../linuxgsm-scripts/entrypoint.sh"]
