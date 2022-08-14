#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

ONLY_SUCCESFUL="true"
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][push] pushing successful images from previous full run"
            echo "[help][push] push.sh [option]"
            echo "[help][push] "
            echo "[help][push] options:"
            echo "[help][push] -a  --all  push also images which aren't succesful "
            exit 0;;
        -a|--all)
            ONLY_SUCCESFUL="false";;
        *)
            echo "[error][push] unknown argument \"$key\"";;
    esac
done

(
    cd "$(dirname "$0")/.."
    mapfile -t results < <(find ./test/results -type f)
    echo "[info][push] found ${#results[@]} result logs"
    push=()
    for result in "${results[@]}"; do
        if ! "$ONLY_SUCCESFUL" || grep -q 'successful' <<< "$result"; then
            mapfile -t images < <(grep -oP -e "(?<=\[info\]\[build\] created tag: ).+" "$result")
            for image in "${images[@]}"; do
                push+=("$image")
                echo "[info][push] $image"
            done
        fi
    done

    sleep 10s
    for image in "${push[@]}"; do
        docker push "$image"
    done
)
