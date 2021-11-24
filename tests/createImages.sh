#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="$1"
IMAGE="jusito/linuxgsm"

# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"

(
    cd "$(dirname "$0")"
    mapfile -d $'\n' -t servers < <(getServerCodeList "$VERSION")
    ./internal/build.sh --no-cache --image "$IMAGE" --version "$VERSION"
    for server_code in "${servers[@]}"; do
        ./internal/build.sh --image "$IMAGE" --version "$VERSION" --latest "$server_code"
    done
)
