#!/bin/sh
set -eux
set -o errexit
set -o nounset

echo 'tzdata tzdata/Areas select Europe' | debconf-set-selections
echo 'tzdata tzdata/Zones/Europe select Paris' | debconf-set-selections
apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends npm
npm install -g gamedig
