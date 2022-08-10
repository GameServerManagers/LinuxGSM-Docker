#!/bin/bash

echo "single.sh $@"

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."

# shellcheck source=test/internal/api_docker.sh
source "$(dirname "$0")/internal/api_docker.sh"
# shellcheck source=test/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"
# shellcheck source=test/steam_test_credentials
source "$(dirname "$0")/steam_test_credentials"



LOGS="false"
LOG_DEBUG="false"
DEBUG="false"
IMAGE="$DEFAULT_DOCKER_REPOSITORY"
RETRY="1"
GAMESERVER=""
BUILD_ONLY="false"
LGSM_GITHUBUSER=""
LGSM_GITHUBREPO=""
LGSM_GITHUBBRANCH=""

build=(./internal/build.sh)
run=(./internal/run.sh)
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][single] single testing of provided gameserver"
            echo "[help][single] single.sh [option] server"
            echo "[help][single] "
            echo "[help][single] options:"
            echo "[help][single] -c  --no-cache      run without docker cache"
            echo "[help][single] -b  --build-only    just build it"
            echo "[help][single] -d  --debug         run gameserver and overwrite entrypoint to bash"
            echo "[help][single]     --image      x  target image"
            echo "[help][single] -l  --logs          print complete docker log afterwards"
            echo "[help][single]     --log-debug     enables LGSM_DEBUG, log can contain your steam credentials, dont share it!"
            echo "[help][single]     --retry         if run failed, rebuild and rerun up to 3 times"
            echo "[help][single]     --git-branch x  sets LGSM_GITHUBBRANCH"
            echo "[help][single]     --git-repo   x  sets LGSM_GITHUBREPO"
            echo "[help][single]     --git-user   x  sets LGSM_GITHUBUSER"
            echo "[help][single]     --skip-lgsm     skip build lgsm"
            echo "[help][single]     --very-fast     overwrite healthcheck, only use it with volumes / lancache because container will else fail pretty fast"
            echo "[help][single]     --version    x  use linuxgsm version x e.g. \"v21.4.1\" can be a commit id(even fork) / branch"
            echo "[help][single]     --volume     x  use volume x e.g. \"lgsm\""
            echo "[help][single] "
            echo "[help][single] server            e.g. gmodserver"
            exit 0;;
        -c|--no-cache)
            build+=(--no-cache);;
        -b|--build-only)
            BUILD_ONLY="true";;
        -d|--debug)
            run+=(--debug)
            DEBUG="true";;
        --image)
            IMAGE="$1"
            shift;;
        -l|--logs)
            LOGS="true"
            LOG_DEBUG="true";;
        --log-debug)
            LOG_DEBUG="true";;
        --retry)
            RETRY="3";;
        --git-branch)
            LGSM_GITHUBBRANCH="$1"
            shift;;
        --git-repo)
            LGSM_GITHUBREPO="$1"
            shift;;
        --git-user)
            LGSM_GITHUBUSER="$1"
            shift;;
        --skip-lgsm)
            build+=(--skip-lgsm);;
        --suffix)
            build+=(--suffix "$1")
            run+=(--suffix "$1" )
            shift;;
        --very-fast)
            run+=(--quick);;
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
                echo "[info][single] additional argument to docker: \"$key\""
                run+=("$key")
            fi;;
    esac
done

if [ -z "$GAMESERVER" ]; then
    echo "[error][single] no gameserver provided"
    exit 1
elif grep -qEe "(^|\s)$GAMESERVER(\s|$)" <<< "${credentials_enabled[@]}" && ! "$BUILD_ONLY"; then
	echo "[info][single] $GAMESERVER can only be tested with steam credential"
	if [ -n "$steam_test_username" ] && [ -n "$steam_test_password" ]; then
    	run+=(-e CONFIGFORCED_steamuser="$steam_test_username" -e CONFIGFORCED_steampass="$steam_test_password")
	else
		echo "[error][single] $GAMESERVER can only be tested with steam credentials, please fill $(realpath "$(dirname "$0")/steam_test_credentials")"
		exit 2
	fi
else
    echo "[warning][single] no steam credentials provided, some servers will fail without it"
fi

if [ -n "$LGSM_GITHUBUSER" ]; then
    run+=(-e "LGSM_GITHUBUSER=$LGSM_GITHUBUSER")
fi
if [ -n "$LGSM_GITHUBREPO" ]; then
    run+=(-e "LGSM_GITHUBREPO=$LGSM_GITHUBREPO")
fi
if [ -n "$LGSM_GITHUBBRANCH" ]; then
    run+=(-e "LGSM_GITHUBBRANCH=$LGSM_GITHUBBRANCH")
fi

CONTAINER="linuxgsm-$GAMESERVER"
build+=(--image "$IMAGE" --latest "$GAMESERVER")
run+=(--image "$IMAGE" --tag "$GAMESERVER" --container "$CONTAINER")
if ! "$DEBUG"; then
    run+=(--detach)
fi
if "$LOG_DEBUG"; then
    run+=(-e LGSM_DEBUG="true")
fi

function handleInterrupt() {
    removeContainer "$CONTAINER"
}
trap handleInterrupt SIGTERM SIGINT

(
    cd "$(dirname "$0")"
    successful="false"
    try="1"
    while [ "$try" -le "$RETRY" ] && ! "$successful"; do
        echo "[info][single] try $try"
        try="$(( try+1 ))"
        removeContainer "$CONTAINER"
        echo "${build[@]}"
        "${build[@]}"

        if "$BUILD_ONLY"; then
            successful="true"
        else
            echo "${run[@]}" | sed -E 's/(steamuser|steampass)=\S+/\1="xxx"/g'
            "${run[@]}"

            if "$DEBUG" || awaitHealthCheck "$CONTAINER"; then
                successful="true"
            fi
            
            echo ""
            echo "[info][single] printing dev-debug-function-order.log"
            docker exec -it "$CONTAINER" cat "dev-debug-function-order.log" || true
            stty sane
            echo ""
            echo "[info][single] printing dev-debug.log"
            docker exec -it "$CONTAINER" cat "dev-debug.log" || true
            echo ""
            stty sane
            
            stopContainer "$CONTAINER"
            if "$LOGS"; then
                printf "[info][single] logs:\n%s\n" "$(docker logs "$CONTAINER" 2>&1 || true)"
            elif ! "$successful"; then
                printf "[info][single] logs:\n%s\n" "$(docker logs -n 20 "$CONTAINER" 2>&1 || true)"
            fi
            printf "[info][single] healthcheck log:\n%s\n" "$(docker inspect -f '{{json .State.Health.Log}}' "$CONTAINER" | jq | sed 's/\\r/\n/g' | sed 's/\\n/\n/g' || true)"
        fi
    done
    removeContainer "$CONTAINER"

    if "$successful"; then
        echo "[info][single] successful"
        exit 0
    else
        echo "[error][single] failed"
        exit 1
    fi
)
