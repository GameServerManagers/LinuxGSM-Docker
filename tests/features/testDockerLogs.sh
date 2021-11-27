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
    ./tests/quick.sh --quick --logs --version "$VERSION" --volume "$VOLUME" "$GAMESERVER" > "$log"
    if grep -qE 'VAC\s*secure\s*mode\s*is\s*activated.' "$log"; then
        rm "$log"
        echo "[info][testDockerLogs] successful"
        exit 0
    else
        echo "[failed][testDockerLogs] failed, check $log"
        tail "$log"
        exit 1
    fi
)
