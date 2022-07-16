#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# shellcheck source=test/internal/api_docker.sh
source "$(dirname "$0")/api_docker.sh"
# shellcheck source=test/internal/api_various.sh
source "$(dirname "$0")/api_various.sh"

server=""
image="$DEFAULT_DOCKER_REPOSITORY"
latest="false"
skip_lgsm="false"
suffix=""
lgsm_version="master"
lgsm_tags_latest=()

build_lgsm=(docker build -f build/Dockerfile)
build_specific=("${build_lgsm[@]}")
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][build] build.sh [option] [server]"
            echo "[help][build] "
            echo "[help][build] options:"
            echo "[help][build] -c  --no-cache     disable cache using"
            echo "[help][build] -i  --image     x  target image, default=$image"
            echo "[help][build]     --latest       tag created image also as latest and according to provided version e.g. lgsm:latest :v21.4.1 :v21.4 :v21"
            echo "[help][build]     --skip-lgsm    dont rebuild lgsm"
            echo "[help][build]     --suffix    x  suffix for docker tag, e.g. \"develop\" will create gmodserver-v21.4.1-develop"
            echo "[help][build] -v  --version   x  use provided lgsm version where x is branch / tag / commit e.g. --version v21.4.1"
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
        --skip-lgsm)
            skip_lgsm="true";;
        --suffix)
            if [ -n "$1" ]; then
                suffix="-$1"
            else
                echo "[warning][build] you provided an empty suffix, skipping"
            fi
            shift;;
        -v|--version)
            lgsm_version="$1"
            if grep -q '^v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' <<< "$lgsm_version"; then
                major="${lgsm_version%%.*}"
                minor="${lgsm_version#*.}"
                minor="${minor%%.*}"
                #patch="${lgsm_version##*.}"
                # "$major.$minor.$patch" not added because equal to version
                lgsm_tags_latest+=("$major.$minor" "$major")
            fi

            build_lgsm+=(--build-arg "ARG_LGSM_VERSION=$lgsm_version")
            build_specific+=(--build-arg "ARG_LGSM_VERSION=$lgsm_version")
            echo "[info][build] using lgsm version $lgsm_version"
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

lgsm_main_tag="$lgsm_version$suffix"
specific_main_tag="$lgsm_version-${server}$suffix"
build_lgsm+=(-t "$image:$lgsm_main_tag" --target linuxgsm .)
build_specific+=(-t "$image:$specific_main_tag" --target specific --build-arg "ARG_LGSM_GAMESERVER=$server" .)

cd "$(dirname "$0")/../.."

# build lgsm image
if ! "$skip_lgsm"; then
    echo "${build_lgsm[@]}"
    "${build_lgsm[@]}"
    echo "[info][build] created tag: $image:$lgsm_main_tag" # used in results as info for push.sh

    if "$latest"; then
        latest_tag="latest"
        if [ -n "$suffix" ]; then
            latest_tag="${suffix:1}"
        fi
        docker tag "$image:$lgsm_main_tag" "$image:$latest_tag"
        echo "[info][build] created tag: $image:${server}$suffix"
        for tag in "${lgsm_tags_latest[@]}"; do
            docker tag "$image:$lgsm_main_tag" "$image:$tag$suffix"
            echo "[info][build] created tag: $image:$tag$suffix"
        done
    fi
fi

# build specific image
if [ -n "$server" ]; then
    echo "${build_specific[@]}"
    "${build_specific[@]}"
    echo "[info][build] created tag: $image:$specific_main_tag"
    if "$latest"; then
        docker tag "$image:$specific_main_tag" "$image:${server}$suffix"
        echo "[info][build] created tag: $image:${server}$suffix"
        for tag in "${lgsm_tags_latest[@]}"; do
            docker tag "$image:$specific_main_tag" "$image:$tag-${server}$suffix"
            echo "[info][build] created tag: $image:$tag-${server}$suffix"
        done
    fi
fi
