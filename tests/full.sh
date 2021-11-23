#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

VERSION=""
GAMESERVER=""
PARRALEL=""
PARRALEL="$(lscpu -p | grep -Ev '^#' | sort -u -t, -k 2,4 | wc -l)"
ROOT_FOLDER="$(realpath "$(dirname "$0")")/.."
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
            GAMESERVER="$key";;
    esac
done

# create results folder
RESULTS="$ROOT_FOLDER/tests/results"
rm -rf "$RESULTS"
mkdir -p "$RESULTS"
(
    working_folder="$(mktemp -d)"
    cd "$working_folder"
    wget -O "linuxgsm.sh" "https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/$VERSION/linuxgsm.sh"
    chmod +x "linuxgsm.sh"
    server_list="$(./linuxgsm.sh list)"
    
    subprocesses=()
    while IFS=$'\n' read -r line; do
        rm -rf "$working_folder" > /dev/null 2>&1
        cd "$ROOT_FOLDER"

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
        
        server_code="$(grep -oE '^\S*' <<< "$line")"
        echo "testing: $server_code"
        if [ -z "$GAMESERVER" ] || [ "$server_code" = "$GAMESERVER" ]; then
            (
                if ./tests/quick.sh --logs --version "$VERSION" "$server_code" > "$RESULTS/$server_code.log" 2>&1; then
                    mv "$RESULTS/$server_code.log" "$RESULTS/successful.$server_code.log"
                else
                    mv "$RESULTS/$server_code.log" "$RESULTS/failed.$server_code.log"
                fi
            ) &
            subprocesses+=("$!")
        fi
    done < <(echo "$server_list")

    echo "successful: $(find "$RESULTS/" -iname "successful.*" | wc -l)"
    echo "failed: $(find "$RESULTS/" -iname "failed.*" | wc -l)"
)
