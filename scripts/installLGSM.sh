#!/bin/sh

set -o errexit
set -o nounset
echo "[installLGSM] installing LGSM"

GROUP_NAME="$USER_NAME"

wget "https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/$LGSM_VERSION/linuxgsm.sh"
chmod +x linuxgsm.sh
