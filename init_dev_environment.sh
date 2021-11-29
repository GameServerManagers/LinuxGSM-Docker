#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

(
    cd "$(dirname "$0")"

    # don't accidentally commit credentials
    git update-index --skip-worktree tests/steam_test_credentials

    # fix permissions
    find tests/ commands/ setup/ -type f -exec chmod u+x "{}" \;
)
