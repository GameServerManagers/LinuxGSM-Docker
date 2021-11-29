#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

VERSION="master"
GAMESERVER=()
PARRALEL=""
PARRALEL="$(lscpu -p | grep -Ev '^#' | sort -u -t, -k 2,4 | wc -l)"
ROOT_FOLDER="$(realpath "$(dirname "$0")/..")"
RERUN="false"
VOLUMES="false"
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][full] testing every feature of specified server"
            echo "[help][full] full.sh [option] [server]"
            echo "[help][full] "
            echo "[help][full] options:"
            echo "[help][full] -c --cpus    x  run x servers in parralel, default x = physical cores"
            echo "[help][full]    --rerun      check results and runs every gameserver which wasn't successful"
            echo "[help][full]    --volumes    use volumes \"linuxgsm-SERVERCODE\""
            echo "[help][full] -v --version x  use linuxgsm version x e.g. \"v21.4.1\""
            echo "[help][full] "
            echo "[help][full] server:"
            echo "[help][full] *empty*         test every server"
            echo "[help][full] gmodserver ...  run only given servers"
            exit 0;;
        -c|--cpus)
            PARRALEL="$1"
            shift;;
        --rerun)
            RERUN="true";;
        --volumes)
            VOLUMES="true";;
        -v|--version)
            VERSION="$1"
            shift;;
        *)
            if grep -qE '^-' <<< "$key"; then
                echo "[error][full] unknown option $key"
                exit 1
            else
                echo "[info][full] only testing servercode \"$key\""
            fi
            GAMESERVER+=("$key");;
    esac
done
testAllServer="$([ "${#GAMESERVER[@]}" = "0" ] && echo true || echo false )"
if [ "$(whoami)" = "root" ]; then
    echo "[error][full] please dont execute me as root, iam invoking linuxgsm.sh directly and this will not work as root"
    exit 1
fi

# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"

# prepare results folder
RESULTS="$ROOT_FOLDER/tests/results"
if [ "${#GAMESERVER[@]}" = "0" ]; then
    if "$RERUN"; then
        find "$RESULTS" -type f ! -name "successful.*" -exec rm -f "{}" \;
    else
        rm -rf "$RESULTS"
    fi
else
    # rerun only remove specific log
    for servercode in "${GAMESERVER[@]}"; do
        rm -rf "${RESULTS:?}/"*".$servercode.log"
    done
fi
mkdir -p "$RESULTS"

(
    echo "[info][full] building linuxgsm base once"
    ./tests/internal/build.sh --version "$VERSION"

    subprocesses=()
    function handleInterrupt() {
        for pid in "${subprocesses[@]}"; do
            kill -s SIGINT "$pid" || true
        done
    }
    trap handleInterrupt SIGTERM SIGINT

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
        
        
        isServercodeInServerlist="$(grep -qF "$server_code" <<< "${GAMESERVER[@]}" && echo true || echo false )"
        serverDidntStartSuccessful="$([ ! -f "$RESULTS/successful.$server_code.log" ] && echo true || echo false )"
        testThisServercode="$( ("$testAllServer" || "$isServercodeInServerlist") && echo true || echo false )"
        rerunIsFine="$( ( ! "$RERUN" || "$serverDidntStartSuccessful" ) && echo true || echo false )"
        if "$testThisServercode" && "$rerunIsFine"; then
            echo "[info][full] testing: $server_code"
            (   
                quick=(./tests/quick.sh --slow --logs --version "$VERSION")
                if "$VOLUMES"; then
                    quick+=(--volume "linuxgsm-$server_code")
                fi
                quick+=("$server_code")

                echo "${quick[@]}"
                if "${quick[@]}" > "$RESULTS/$server_code.log" 2>&1; then
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

    echo "[info][full] successful: $(find "$RESULTS/" -iname "successful.*" | wc -l)"
    echo "[info][full] failed: $(find "$RESULTS/" -iname "failed.*" | wc -l)"
)
