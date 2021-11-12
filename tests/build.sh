#!/bin/bash

server=""
lgsm_version=""
clear=""
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "build.sh [option] [server]"
            echo ""
            echo "options:"
            echo "-v        x       use provided lgsm version where x is branch / tag / commit"
            echo "--version x       e.g. --version v21.4.1"
            echo "-c                disable cache using"
            echo "--no-cache"
            echo ""
            echo "server:"
            echo "gmodserver        build linuxgsm image and specific gmodserver"
            echo "..."
            exit 0;;
        -v|--version)
            lgsm_version="--build-arg=\"LGSM_VERSION=$1\" --no-cache "
            echo "using lgsm version ${lgsm_version:-default}"
            shift
            ;;
        -c|--no-cache)
            clear="--no-cache";;
        *)
            echo "$key is server"
            server="$key";;
    esac
done

source "$(dirname "$0")/config" 
cd "$(dirname "$0")/.."

cmd=(docker build -t "$IMAGE:lgsm" $clear --target linuxgsm $lgsm_version .)
echo "${cmd[@]}"
"${cmd[@]}"
if [ -n "$server" ]; then
    cmd=(docker build -t "$IMAGE:specific" --build-arg "LGSM_GAMESERVER=$server" $lgsm_version .)
    echo "${cmd[@]}"
    "${cmd[@]}"
fi
