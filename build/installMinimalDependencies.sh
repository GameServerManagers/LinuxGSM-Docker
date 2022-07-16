#!/bin/sh

# install minimal dependencies needed for build / runtime scripts

set -o errexit
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi
echo "[info][installMinimalDependencies] installing ..."

apt-get update
# iproute2, fix "-o: command not found", fix "ss: command not found"
# XXX it would be better to install minimal deps to download and parse all section
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    file \
    iproute2 \
    jq \
    locales \
    tmux \
    unzip \
    wget 
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
