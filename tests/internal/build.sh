#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/api_docker.sh"
# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/api_various.sh"

server=""
lgsm_version=()
clear=""
image="lgsm-test"
tag_lgsm="dev"
latest="false"
push="false"
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
            echo "--latest          every created image is also tagged as latest"
            echo "--push            every image is also pushed"
            echo ""
            echo "server:"
            echo "gmodserver        build linuxgsm image and specific gmodserver"
            echo "..."
            exit 0;;
        -v|--version)
            tag_lgsm="$1"
            lgsm_version=("--build-arg" "ARG_LGSM_VERSION=$1")
            echo "using lgsm version ${lgsm_version:-default}"
            shift
            ;;
        -i|--image)
            image="$1"
            shift;;
        --latest)
            latest="true";;
        --push)
            push="true";;
        -c|--no-cache)
            clear="--no-cache";;
        *)
            echo "$key is server"
            server="$key";;
    esac
done

cd "$(dirname "$0")/../.."

#shellcheck disable=SC2206
cmd=(docker build -t "$image:$tag_lgsm" $clear --target linuxgsm ${lgsm_version[@]} .)
echo "${cmd[@]}"
"${cmd[@]}"

if "$push"; then
    docker push "$image:$tag_lgsm"
fi

if "$latest"; then
    docker tag "$image:$tag_lgsm" "$image:latest"
    if "$push"; then
        docker push "$image:latest"
    fi
fi


if [ -n "$server" ]; then
    #shellcheck disable=SC2206
    cmd=(docker build -t "$image:${server}_$tag_lgsm" --build-arg "ARG_LGSM_GAMESERVER=$server" ${lgsm_version[@]} .)
    echo "${cmd[@]}"
    "${cmd[@]}"

    if "$push"; then
        docker push "$image:${server}_$tag_lgsm"
    fi
    if "$latest"; then
        docker tag "$image:${server}_$tag_lgsm" "$image:${server}"
        if "$push"; then
        docker push "$image:${server}"
    fi
    fi
fi
