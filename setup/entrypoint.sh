#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

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
    lgsm-update
fi

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
echo "entrypoint ended"

