#!/bin/sh

set -o errexit
set -o nounset

VERSION="$1"
SHA256="$2"
TARGET="/usr/local/bin/supercronic"

wget -O "$TARGET" "https://github.com/aptible/supercronic/releases/download/$VERSION/supercronic-linux-amd64"
sha256sum "$TARGET" | grep -qF "$SHA256 " || exit 1
chmod +x "$TARGET"
