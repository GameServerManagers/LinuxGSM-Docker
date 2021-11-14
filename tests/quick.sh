#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source "$(dirname "$0")/internal/api_docker.sh"
source "$(dirname "$0")/internal/api_various.sh"

VERSION=""
GAMESERVER=""
VOLUME=""
DEBUG=""
clear=""
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "quick testing of provided gameserver"
            echo "quick.sh [option] server"
            echo ""
            echo "options:"
            echo "--version x    use linuxgsm version x e.g. \"v21.4.1\""
            echo "--volume  x    use volume x e.g. \"lgsm\""
            echo "-d             run gameserver and overwrite entrypoint to bash"
            echo "--debug"
            echo "-c             run without docker cache"
            echo "--no-cache"
            echo ""
            echo "server         e.g. gmodserver"
            exit 0;;
        --version)
            VERSION="--version \"$1\""
            shift;;
        --volume)
            VOLUME="--volume $1"
            shift;;
        -c|--no-cache)
            clear="--no-cache";;
        -d|--debug)
            DEBUG="--debug";;
        *)
            if grep -qE '^-' <<< "$key"; then
                echo "unknown option $key"
                exit 1
            fi
            GAMESERVER="$key";;
    esac
done

if [ -z "$GAMESERVER" ]; then
    echo "ERROR no gameserver provided"
    exit 1
fi
CONTAINER="linuxgsm-$GAMESERVER"

(
    cd "$(dirname "$0")"
    removeContainer "$CONTAINER"
    ./internal/build.sh $clear "$VERSION" "$GAMESERVER"
    ./internal/run.sh --container "$CONTAINER" --detach $VOLUME specific
    if awaitHealthCheck "$CONTAINER"; then
        echo "successful"
    else
        echo "failed"
    fi
    removeContainer "$CONTAINER"
)
