#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="$1"
if [ "${1}" = "--version" ] || [ "${1}" = "-v" ]; then
    VERSION="$2"
fi
CLEAR="$( grep -qE '(-c|--clear)' <<< "$@" && echo true || echo false )"
GAMESERVER="gmodserver"
VOLUME="linuxgsm-$GAMESERVER-testFeatures"


(
    cd "$(dirname "$0")/.."
    if "$CLEAR"; then
        docker volume rm "$VOLUME" || true
    fi
    ./tests/single.sh --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"

    ./tests/features/testCron.sh           "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/features/testDockerLogs.sh     "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/features/testFixPermissions.sh "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/features/testUpdateUidGuid.sh  "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/features/testLgsmUpdate.sh     "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/features/testLoadConfig.sh     "$VERSION" "$GAMESERVER" "$VOLUME"

    echo "[info][features] successful"
)