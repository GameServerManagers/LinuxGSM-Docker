#!/bin/bash

set -o errexit
set -o nounset

(
    cd "$(dirname "$0")/.."

    files=()
    mapfile -d $'\0' files < <( find commands setup tests -type f ! -iname "*.log" -print0 )

    shellcheck "${files[@]}"
)
