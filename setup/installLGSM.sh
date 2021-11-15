#!/bin/sh

set -o errexit
set -o nounset
echo "[installLGSM] installing LGSM"

wget -O "$LGSM_SCRIPTS/linuxgsm.sh" "https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/$LGSM_VERSION/linuxgsm.sh"
chmod +x "$LGSM_SCRIPTS/linuxgsm.sh"
