#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

VERSION="$1"

(
    cd "$(dirname "$0")"
    
    # build clean version
    ./build.sh --no-cache --version "$VERSION"

    # run linuxgsm once
    
)