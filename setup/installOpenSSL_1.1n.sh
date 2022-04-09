#!/bin/bash

set -euo pipefail
version="1.1.1n"
package="1748639999ed79b998e4fe4a6d292ed8e874736a"

apt-get update
apt-get install -y python3-pip
pip3 install conan
conan profile new default --detect
conan profile update settings.compiler.libcxx=libstdc++11 default
conan download -p "$package" "openssl/$version@_/_"

(
    cd ~/".conan/data/openssl/$version/_/_/package/$package/lib/"
    cp *.so "/usr/local/lib"
    cd "/usr/local/lib"
    for file in *.so; do
        mv "$file" "$file.1.1"
    done
)
# reindex with: ldconfig /usr/local/lib
# ldd *.so should be fine and ldconfig -p should list the so
