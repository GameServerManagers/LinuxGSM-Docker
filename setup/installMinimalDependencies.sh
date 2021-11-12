#!/bin/sh

set -o errexit
set -o nounset
echo "[installMinimalDependencies] installing ..."

apt-get update
# curl / wget needed for lgsm
# iproute2, fix "-o: command not found", fix "ss: command not found"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates wget locales curl iproute2
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# verify gosu is working
gosu nobody true
