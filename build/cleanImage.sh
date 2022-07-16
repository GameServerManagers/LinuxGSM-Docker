#!/bin/sh

# clean/shrink dockerimage and removes unnecessary files
# e.g. remove apt cache and build scripts

set -o errexit
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi
echo "[info][cleanImage] cleaning image"

apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/* >> /dev/null 2>&1 || true
rm -rf "${LGSM_PATH:?}"/* /tmp/* /var/tmp/* || true
rm "$LGSM_SCRIPTS/installMinimalDependencies.sh" \
    "$LGSM_SCRIPTS/installLGSM.sh" \
    "$LGSM_SCRIPTS/installGamedig.sh" \
    "$LGSM_SCRIPTS/setupUser.sh" \
    "$LGSM_PATH"/* >> /dev/null 2>&1 || true
