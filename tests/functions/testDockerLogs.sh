#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="$1"
GAMESERVER="$2"
VOLUME="$3"

(
    cd "$(dirname "$0")/../.."
    log="tests/functions/testDockerLogs.log"
    ./tests/quick.sh --logs --version "$VERSION" --volume "$VOLUME" "$GAMESERVER" > "$log"
    if grep -qE 'VAC\s*secure\s*mode\s*is\s*activated.' "$log"; then
        rm "$log"
        echo "[testDockerLogs] successful"
        exit 0
    else
        echo "[testDockerLogs] failed, check $log"
        exit 1
    fi
)
