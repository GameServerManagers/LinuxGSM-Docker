#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# save list of currently installed packages for later so we can clean up
savedAptMark="$(apt-mark showmanual)"
apt-get update
apt-get install -y --no-install-recommends ca-certificates wget
if ! command -v gpg; then
    apt-get install -y --no-install-recommends gnupg2 dirmngr
elif gpg --version | grep -q '^gpg (GnuPG) 1\.'; then
# "This package provides support for HKPS keyservers." (GnuPG 1.x only)
    apt-get install -y --no-install-recommends gnupg-curl
fi
rm -rf /var/lib/apt/lists/*

dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"
wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"

# verify the signature
export GNUPGHOME="$(mktemp -d)"
gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu
command -v gpgconf && gpgconf --kill all || :
rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc

chmod +x /usr/local/bin/gosu
# verify that the binary works
gosu --version
gosu nobody true