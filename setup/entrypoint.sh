#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi

if ! "$LGSM_USE_GAMEDIG"; then
	npm uninstall -g gamedig
fi

cd "$LGSM_PATH"
rm "$LGSM_STARTED" > /dev/null 2>&1 || true

lgsm-update-uid-gid
lgsm-fix-permission
lgsm-cron-init

# check if wished server is provided
if [ ! -e "$LGSM_GAMESERVER" ]; then
    lgsm-init
    lgsm-load-config
    lgsm-auto-install
else
    lgsm-init
    if ! lgsm-update; then
        echo ""
        echo "[error][entrypoint] update failed, remove $LGSM_GAMESERVER from volume if you want to reinstall it"
        echo "[error][entrypoint] docker run --rm -v VOLUME_NAME:/home alpine:3.15 rm -vf /home/$LGSM_GAMESERVER"
        exit 1
    fi
    lgsm-load-config
fi

lgsm-start
trap lgsm-stop SIGTERM SIGINT
lgsm-cron-start > /dev/null 2>&1 &
touch "$LGSM_STARTED"

is_running="true"
while "$is_running"; do
    # tmux in background with log usable for docker
    # alternative solution: lgsm-tmux-attach | tee /dev/tty &
    rm tmux.pipe > /dev/null 2>&1 || true
    mkfifo tmux.pipe
    lgsm-tmux-attach | tee tmux.pipe &
    while read -r line; do
        echo "$line"
    done < tmux.pipe

    echo "[info][entrypoint] server stopped"
    is_running="false"
    current_running_lgsm_alias="$(< "$LGSM_CURRENT_COMMAND")"
    for lgsm_cmd in monitor update restart force-update validate; do
        if grep -qe "$lgsm_cmd" <<< "$current_running_lgsm_alias"; then
            echo "[info][entrypoint] lgsm command \"$lgsm_cmd\" is being executed and is permitted to stop the server, reattaching to tmux"
            is_running="true"
        fi
    done
done
rm "$LGSM_STARTED" > /dev/null 2>&1 || true
echo "[info][entrypoint] entrypoint ended"
