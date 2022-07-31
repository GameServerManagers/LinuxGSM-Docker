#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
    touch ".dev-debug"
    rm dev-debug*.log > /dev/null 2>&1 || true # remove from last execution
else
    rm ".dev-debug" || true
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
fi
lgsm-load-config

# workaround libssl
sed -i -E 's/,libssl1.1[^,]*//' ./lgsm/data/ubuntu-22.04.csv
lgsm-start || (
    exitcode="$?"
    echo "[error][entrypoint] initial start failed, printing console.log"
    cat "$LGSM_PATH/log/console/$LGSM_GAMESERVER-console.log" || true
    exit "$exitcode"
)
trap lgsm-stop SIGTERM SIGINT
lgsm-cron-start > /dev/null 2>&1 &
touch "$LGSM_STARTED"

is_running="true"
first_start="$(date +'%s')"
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
    errorcode="1"
    is_running="false"

    # check if server is stopped on purpose
    current_running_lgsm_alias="$(< "$LGSM_CURRENT_COMMAND")"
    for lgsm_cmd in monitor update restart force-update validate; do
        if grep -qe "$lgsm_cmd" <<< "$current_running_lgsm_alias"; then
            echo "[info][entrypoint] lgsm command \"$lgsm_cmd\" is being executed and is permitted to stop the server, reattaching to tmux"
            errorcode="0"
            is_running="true"
            lgsm-start
        fi
    done

    # retry in first 60s, e.g. cod4server needs a second try
    current_time="$(date +'%s')"
    if ! "$is_running" && [ "$((current_time - first_start))" -lt "60" ]; then
        echo "[warning][entrypoint] server crashed within 60 seconds, restarting"
        errorcode="0"
        is_running="true"
        lgsm-start
    fi
done
rm "$LGSM_STARTED" > /dev/null 2>&1 || true
echo "[info][entrypoint] entrypoint ended with exitcode=$errorcode"
exit "$errorcode"
