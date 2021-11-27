#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."

# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/internal/api_docker.sh"
# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"


GAMESERVER=""
LOGS="false"

build=(./internal/build.sh)
run=(./internal/run.sh --quick)
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][quick] quick testing of provided gameserver"
            echo "[help][quick] quick.sh [option] server"
            echo "[help][quick] "
            echo "[help][quick] options:"
            echo "[help][quick] -c  --no-cache   run without docker cache"
            echo "[help][quick] -d  --debug      run gameserver and overwrite entrypoint to bash"
            echo "[help][quick] -l  --logs       print last log lines after run"
            echo "[help][quick]     --version x  use linuxgsm version x e.g. \"v21.4.1\""
            echo "[help][quick]     --volume  x  use volume x e.g. \"lgsm\""
            echo "[help][quick] "
            echo "[help][quick] server           e.g. gmodserver"
            exit 0;;
        -c|--no-cache)
            build+=(--no-cache);;
        -d|--debug)
            run+=(--debug);;
        -l|--logs)
            LOGS="true";;
        --version)
            build+=(--version "$1")
            shift;;
        --volume)
            run+=(--volume "$1")
            shift;;
        *)
            if [ -z "$GAMESERVER" ]; then
                GAMESERVER="$key"
            else
                echo "[quick.sh] additional argument to docker: \"$key\""
                run+=("$key")
            fi;;
    esac
done

if [ -z "$GAMESERVER" ]; then
    echo "ERROR no gameserver provided"
    exit 1
fi
CONTAINER="linuxgsm-$GAMESERVER"
build+=(--latest "$GAMESERVER")
run+=(--container "$CONTAINER" --detach --tag "$GAMESERVER")

function handleInterrupt() {
    removeContainer "$CONTAINER"
}
trap handleInterrupt SIGTERM SIGINT

(
    cd "$(dirname "$0")"
    removeContainer "$CONTAINER"
    
    echo "${build[@]}"
    "${build[@]}"
    echo "${run[@]}"
    "${run[@]}"

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
        echo "[info][quick] successful"
        exit 0
    else
        echo "[error][quick] failed"
        exit 1
    fi
)
