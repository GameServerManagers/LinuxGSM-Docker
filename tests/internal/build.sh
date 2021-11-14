#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

source "$(dirname "$0")/api_docker.sh"
source "$(dirname "$0")/api_various.sh"

server=""
lgsm_version=""
clear=""
image="lgsm-test"
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
            echo "-i        x       target image, default=lgsm-test"
            echo "--image   x"
            echo ""
            echo "server:"
            echo "gmodserver        build linuxgsm image and specific gmodserver"
            echo "..."
            exit 0;;
        -v|--version)
            lgsm_version="--build-arg=\"LGSM_VERSION=$1\""
            echo "using lgsm version ${lgsm_version:-default}"
            shift
            ;;
        -i|--image)
            image="$key";;
        -c|--no-cache)
            clear="--no-cache";;
        *)
            echo "$key is server"
            server="$key";;
    esac
done

cd "$(dirname "$0")/../.."

cmd=(docker build -t "$image:lgsm" $clear --target linuxgsm $lgsm_version .)
echo "${cmd[@]}"
"${cmd[@]}"
if [ -n "$server" ]; then
    cmd=(docker build -t "$image:specific" --build-arg "LGSM_GAMESERVER=$server" $lgsm_version .)
    echo "${cmd[@]}"
    "${cmd[@]}"
fi
