#!/bin/bash

source "$(dirname "$0")/config" 

args=()
debug=""
tag=""
volume=""
remove="false"
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "run.sh [option] tag [args]"
            echo ""
            echo "options:"
            echo "-d            set entrypoint to bash"
            echo "--debug"
            echo "-v            use volume instead of clean"
            echo "--volume"
            echo ""
            echo "tag:"
            echo "lgsm          run lgsm image"
            echo "specific      run last created specific image $IMAGE:$tag"
            echo ""
            echo "args:"
            echo "every other argument is added to docker run ... IMAGE [args] "
            exit 0;;
        -d|--debug)
            debug="--entrypoint bash";;
        -v|--volume)
            volume="-v $1:/home/linuxgsm"
            shift;;
        lgsm|specific)
            tag="$key";;
        *)
            echo "$key is argument for docker container"
            args+=("$key");;
    esac
done


if [ -z "$tag" ]; then
    echo "please provide the tag to execute as first argument lgsm or specific"
    exit 1
fi


cmds=(docker run -it --rm --name "$CONTAINER" $volume $debug "$IMAGE:$tag")
for arg in "$@"; do
    if [ "$arg" != "$1" ]; then
        cmds+=("$arg")
    fi
done

echo "${cmds[@]}"
"${cmds[@]}"

