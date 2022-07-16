#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

tools=(jq)

(
    cd "$(dirname "$0")"

    if which sudo > /dev/null 2>&1; then
        sudo chown -R "$(whoami)" ./*
    fi

    # check tools jq
    for tool in "${tools[@]}"; do
        if ! which "$tool" > /dev/null 2>&1; then
            echo "[warning][init_dev_environment] please install \"$tool\""
        fi
    done

    # don't accidentally commit credentials
    git update-index --skip-worktree test/steam_test_credentials

    # fix permissions
    find test/ runtime/ build/ -type f -exec chmod u+x "{}" \;
)
