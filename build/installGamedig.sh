#!/bin/bash

set -o errexit
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi

echo 'tzdata tzdata/Areas select Europe' | debconf-set-selections
echo 'tzdata tzdata/Zones/Europe select Berlin' | debconf-set-selections

apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends xz-utils jq

NODE_VERSION="v16.14.0"
wget "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"
mkdir -p "/usr/local/lib/nodejs"
tar -xJvf "node-$NODE_VERSION-linux-x64.tar.xz" -C "/usr/local/lib/nodejs"
rm "node-$NODE_VERSION-linux-x64.tar.xz"

mapfile -t npm_bin < <(find "/usr/local/lib/nodejs/node-$NODE_VERSION-linux-x64/bin/" ! -type d -exec basename "{}" \;)
for bin in "${npm_bin[@]}"; do
    ln -vs "/usr/local/lib/nodejs/node-$NODE_VERSION-linux-x64/bin/$bin" "/usr/local/bin/$bin"
done

node -v
npm version
npx -v
npm install -g gamedig
ln -vs "/usr/local/lib/nodejs/node-$NODE_VERSION-linux-x64/bin/gamedig" "/usr/local/bin/gamedig"

command -v gamedig
command -v jq