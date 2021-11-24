#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

VERSION="master"
GAMESERVER=()
PARRALEL=""
PARRALEL="$(lscpu -p | grep -Ev '^#' | sort -u -t, -k 2,4 | wc -l)"
ROOT_FOLDER="$(realpath "$(dirname "$0")/..")"
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "testing every feature of specified server"
            echo "full.sh [option] [server]"
            echo ""
            echo "options:"
            echo "-v        x"
            echo "--version x    use linuxgsm version x e.g. \"v21.4.1\""
            echo "-c        x    run x servers in parralel, default x = physical cores"
            echo "--cpus    x"
            echo ""
            echo "server         default empty = all, otherwise e.g. gmodserver"
            exit 0;;
        -v|--version)
            VERSION="$1"
            shift;;
        -c|--cpus)
            PARRALEL="$1"
            shift;;
        *)
            if grep -qE '^-' <<< "$key"; then
                echo "unknown option $key"
                exit 1
            fi
            GAMESERVER+=("$key");;
    esac
done

# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"

# create results folder
RESULTS="$ROOT_FOLDER/tests/results"
if [ "${#GAMESERVER[@]}" = "0" ]; then
    rm -rf "$RESULTS"
else
    # rerun only remove specific log
    for servercode in "${GAMESERVER[@]}"; do
        rm -rf "${RESULTS:?}/"*".$servercode.log"
    done
fi
mkdir -p "$RESULTS"

(
    subprocesses=()
    mapfile -d $'\n' -t servers < <(getServerCodeList "$VERSION")
    for server_code in "${servers[@]}"; do
        cd "$ROOT_FOLDER"

        # only start $PARRALEL amount of tests
        while [ "${#subprocesses[@]}" -ge "$PARRALEL" ]; do
            sleep 1s
            temp=()
            for pid in "${subprocesses[@]}"; do
                if ps -p "$pid" -o pid= > /dev/null 2>&1; then 
                    temp+=("$pid")
                fi
            done
            subprocesses=("${temp[@]}")
        done
        
        if [ "${#GAMESERVER[@]}" = "0" ] || grep -qF "$server_code" <<< "${GAMESERVER[@]}"; then
            echo "testing: $server_code"
            (
                if ./tests/quick.sh --logs --version "$VERSION" "$server_code" > "$RESULTS/$server_code.log" 2>&1; then
                    mv "$RESULTS/$server_code.log" "$RESULTS/successful.$server_code.log"
                else
                    mv "$RESULTS/$server_code.log" "$RESULTS/failed.$server_code.log"
                fi
            ) | tee /dev/tty > /dev/null 2>&1 &
            subprocesses+=("$!")
        fi
    done

    # await every job is done
    while [ "${#subprocesses[@]}" -gt "0" ]; do
        sleep 1s
        temp=()
        for pid in "${subprocesses[@]}"; do
            if ps -p "$pid" -o pid= > /dev/null 2>&1; then 
                temp+=("$pid")
            fi
        done
        subprocesses=("${temp[@]}")
    done

    echo "successful: $(find "$RESULTS/" -iname "successful.*" | wc -l)"
    echo "failed: $(find "$RESULTS/" -iname "failed.*" | wc -l)"
)
