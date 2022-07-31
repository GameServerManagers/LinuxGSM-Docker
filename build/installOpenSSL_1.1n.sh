#!/bin/bash

set -euo pipefail
version="1.1.1n"

apt-get update
apt-get install -y python3-pip gcc-multilib
pip3 install --force-reinstall conan
conan profile new default --detect
conan profile update settings.compiler.libcxx=libstdc++11 default
conan install -if "$(mktemp -d)" -s arch=x86 -s arch_build=x86 --build=missing -o openssl:shared=True -s compiler.libcxx=libstdc++11 "openssl/$version@_/_"
mkdir -p "/usr/local/lib/openssl_x86"
cp -vf ~/.conan/data/openssl/"$version"/_/_/package/*/lib/*.so.1.1 "/usr/local/lib/openssl_x86"
conan install -if "$(mktemp -d)" -s arch=x86_x64 -s arch_build=x86_x64 --build=missing -o openssl:shared=True -s compiler.libcxx=libstdc++11 "openssl/$version@_/_"
mkdir -p "/usr/local/lib/openssl_x64"
cp -vf ~/.conan/data/openssl/"$version"/_/_/package/*/lib/*.so.1.1 "/usr/local/lib/openssl_x64"
# reindex with: ldconfig /usr/local/lib
# ldd *.so should be fine and ldconfig -p should list the so
