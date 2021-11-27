#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="$1"
CLEAR="$( grep -qE '(-c|--clear)' <<< "$@" && echo true || echo false )"
GAMESERVER="gmodserver"
VOLUME="linuxgsm-$GAMESERVER-testFeatures"


(
    cd "$(dirname "$0")/.."
    if "$CLEAR"; then
        docker volume rm "$VOLUME" || true
    fi
    ./tests/quick.sh --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"

    ./tests/functions/testCron.sh           "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/functions/testDockerLogs.sh     "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/functions/testFixPermissions.sh "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/functions/testUpdateUidGuid.sh  "$VERSION" "$GAMESERVER" "$VOLUME"
    ./tests/functions/testLgsmUpdate.sh     "$VERSION" "$GAMESERVER" "$VOLUME"

    echo "[info][features] successful"
)
