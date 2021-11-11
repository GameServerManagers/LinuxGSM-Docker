#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

cd "$LGSM_PATH"

lgsm-update-uid-gid
lgsm-fix-permission

# check if wished server is provided
if [ ! -e "$LGSM_GAMESERVER" ]; then
    echo "installing $LGSM_GAMESERVER"
    lgsm-init
    lgsm-auto-install
else
    lgsm-update
fi

isRunning="true"
function stopServer() {
    lgsm-stop
    isRunning="false"
}

lgsm-start
trap stopServer SIGTERM SIGINT

echo "Started linuxgsm waiting for tmux"

while "$isRunning"; do
    lgsm-tmux-attach
	sleep 1s
done