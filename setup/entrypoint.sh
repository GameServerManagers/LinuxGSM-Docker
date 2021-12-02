#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi

cd "$LGSM_PATH"
rm "$LGSM_STARTED" > /dev/null 2>&1 || true

lgsm-update-uid-gid
lgsm-fix-permission
lgsm-cron-init

# check if wished server is provided
if [ ! -e "$LGSM_GAMESERVER" ]; then
    lgsm-init
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
lgsm-start
trap lgsm-stop SIGTERM SIGINT
lgsm-cron-start > /dev/null 2>&1 &
touch "$LGSM_STARTED"

# tmux in background with log usable for docker
# alternative solution: lgsm-tmux-attach | tee /dev/tty &
rm tmux.pipe > /dev/null 2>&1 || true
mkfifo tmux.pipe
lgsm-tmux-attach | tee tmux.pipe &
while read -r line; do
    echo "$line"
done < tmux.pipe
rm "$LGSM_STARTED" > /dev/null 2>&1 || true
echo "[info][entrypoint] entrypoint ended"

