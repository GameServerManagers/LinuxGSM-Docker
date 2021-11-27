#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/api_docker.sh"
# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/api_various.sh"

server=""
image="lgsm-test"
tag_lgsm="dev"
latest="false"
push="false"

build_lgsm=(docker build)
build_specific=(docker build)
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][build] build.sh [option] [server]"
            echo "[help][build] "
            echo "[help][build] options:"
            echo "[help][build] -c  --no-cache    disable cache using"
            echo "[help][build] -i  --image    x  target image, default=lgsm-test"
            echo "[help][build]     --latest      every created image is also tagged as latest"
            echo "[help][build]     --push        every image is also pushed"
            echo "[help][build] -v  --version  x  use provided lgsm version where x is branch / tag / commit e.g. --version v21.4.1"
            echo "[help][build] "
            echo "[help][build] server:"
            echo "[help][build] gmodserver        build linuxgsm image and specific gmodserver"
            exit 0;;
        -c|--no-cache)
            build_lgsm+=(--no-cache);;
        -i|--image)
            image="$1"
            shift;;
        --latest)
            latest="true";;
        --push)
            push="true";;
        -v|--version)
            tag_lgsm="$1"
            build_lgsm+=(--build-arg "ARG_LGSM_VERSION=$1")
            build_specific+=(--build-arg "ARG_LGSM_VERSION=$1")
            echo "[info][build] using lgsm version $1"
            shift;;
        *)
            if [ -z "$server" ]; then
                echo "[info][build] $key is server"
                server="$key"
            else
                echo "[error][build] server is already set to \"$server\" but you provided a second one \"$key\""
                exit 1
            fi
    esac
done
build_lgsm+=(-t "$image:$tag_lgsm" --target linuxgsm .)
build_specific+=(-t "$image:${server}_$tag_lgsm" --build-arg "ARG_LGSM_GAMESERVER=$server" .)

cd "$(dirname "$0")/../.."

# build lgsm image
echo "${build_lgsm[@]}"
"${build_lgsm[@]}"

if "$push"; then
    docker push "$image:$tag_lgsm"
fi
if "$latest"; then
    docker tag "$image:$tag_lgsm" "$image:latest"
    if "$push"; then
        docker push "$image:latest"
    fi
fi

# build specific image
if [ -n "$server" ]; then
    echo "${build_specific[@]}"
    "${build_specific[@]}"

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
