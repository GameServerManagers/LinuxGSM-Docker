#!/bin/sh

set -o errexit
set -o nounset
echo "[installLGSM] installing LGSM"

GROUP_NAME="$USER_NAME"

wget "https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/$LGSM_VERSION/linuxgsm.sh"
chown "$USER_NAME:$GROUP_NAME" linuxgsm.sh
chmod +x linuxgsm.sh
