#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."

# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/internal/api_docker.sh"
# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"

VERSION=()
GAMESERVER=""
VOLUME=()
DEBUG=""
CLEAR=""
LOGS="false"
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
            echo "--logs         print last log lines after run"
            echo "-l"
            echo ""
            echo "server         e.g. gmodserver"
            exit 0;;
        --version)
            VERSION=("--version" "$1")
            shift;;
        --volume)
            VOLUME=("--volume" "$1")
            shift;;
        -c|--no-cache)
            CLEAR="--no-cache";;
        -d|--debug)
            DEBUG="--debug";;
        -l|--logs)
            LOGS="true";;
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

function handleInterrupt() {
    removeContainer "$CONTAINER"
}
trap handleInterrupt SIGTERM SIGINT

(
    cd "$(dirname "$0")"
    removeContainer "$CONTAINER"
    #shellcheck disable=SC2068
    ./internal/build.sh $CLEAR ${VERSION[@]} --latest "$GAMESERVER"
    #shellcheck disable=SC2068
    ./internal/run.sh --container "$CONTAINER" --detach ${VOLUME[@]} "$DEBUG" --tag "$GAMESERVER"

    successful="false"
    if awaitHealthCheck "$CONTAINER"; then
        successful="true"
    fi
    stopContainer "$CONTAINER"
    if "$LOGS"; then
        docker logs "$CONTAINER"
    fi
    removeContainer "$CONTAINER"

    if "$successful"; then
        echo "successful"
        exit 0
    else
        echo "failed"
        exit 1
    fi
)
