#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."

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
    ./test/single.sh --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"

    ./test/features/testCron.sh           "$VERSION" "$GAMESERVER" "$VOLUME"
    ./test/features/testDockerLogs.sh     "$VERSION" "$GAMESERVER" "$VOLUME"
    ./test/features/testFixPermissions.sh "$VERSION" "$GAMESERVER" "$VOLUME"
    ./test/features/testUpdateUidGuid.sh  "$VERSION" "$GAMESERVER" "$VOLUME"
    #TODO: ./test/features/testLgsmUpdate.sh     "$VERSION" "$GAMESERVER" "$VOLUME"
    #TODO: ./test/features/testLoadConfig.sh     "$VERSION" "$GAMESERVER" "$VOLUME"

    echo "[info][features] successful"
)
