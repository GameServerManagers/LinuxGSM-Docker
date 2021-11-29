#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# branch which doesn't get any suffix
MAIN_BRANCH="master"
CURRENT_BRANCH="$(git branch --show-current)"
IMAGE="gameservermanagers/linuxgsm-docker"
VERSION=""
SUFFIX=""
DEFAULT_SUFFIX=""
if [ "$MAIN_BRANCH" != "$CURRENT_BRANCH" ]; then
    DEFAULT_SUFFIX="${CURRENT_BRANCH//\//_}"
fi

build_lgsm=(./internal/build.sh --latest)
build_specific=(./internal/build.sh --latest)
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][createImages] createImages.sh [option] version"
            echo "[help][createImages] "
            echo "[help][createImages] options:"
            echo "[help][createImages] -c  --no-cache    disable cache using for initial lgsm creation"
            echo "[help][createImages] -i  --image    x  target image, default=$IMAGE"
            echo "[help][createImages]     --push        every image is also pushed"
            echo "[help][createImages]     --suffix   x  suffix for docker tag, current default=\"$DEFAULT_SUFFIX\" e.g. \"develop\" will create gmodserver-v21.4.1-develop"
            echo "[help][createImages] "
            echo "[help][createImages] version:"
            echo "[help][createImages] v21.4.1           can be tag / branch / commit"
            exit 0;;
        -c|--no-cache)
            build_lgsm+=(--no-cache);;
        -i|--image)
            IMAGE="$1"
            shift;;
        --push)
            build_lgsm+=(--push)
            build_specific+=(--push);;
        --suffix)
            SUFFIX="$1"
            shift;;
        -v|--version)
            VERSION="$1"
            echo "[info][createImages] using lgsm version $1"
            shift;;
        *)
            VERSION="$key"
            echo "[info][createImages] using lgsm version $VERSION";;
    esac
done
if [ -z "$VERSION" ]; then
    echo "[error][createImages] lgsm version is required"
    exit 1
fi

if [ -z "$SUFFIX" ]; then
    SUFFIX="$DEFAULT_SUFFIX"
fi

build_lgsm+=( --image "$IMAGE" --version "$VERSION" --suffix "$SUFFIX" )
build_specific+=( --image "$IMAGE" --version "$VERSION" --suffix "$SUFFIX" )

# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"

(
    cd "$(dirname "$0")"
    echo "[info][createImages] removing images with suffix \"$SUFFIX\" before recreating"
    for image in $(docker images -q "$IMAGE:*$SUFFIX"); do
        docker rmi -f "$image"
    done

    mapfile -d $'\n' -t servers < <(getServerCodeList "$VERSION")
    echo "${build_lgsm[@]}"
    "${build_lgsm[@]}"
    for server_code in "${servers[@]}"; do
        echo "${build_specific[@]}" "$server_code"
        "${build_specific[@]}" "$server_code"
    done
)
