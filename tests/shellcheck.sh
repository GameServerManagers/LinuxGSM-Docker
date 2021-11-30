#!/bin/bash

set -o errexit
set -o nounset

(
    cd "$(dirname "$0")/.."

    files=()
    mapfile -d $'\0' files < <( find commands setup tests -type f ! -iname "*.log" ! -iname "*.yml" -print0 )

    echo "[info][shellcheck] testing on ${#files[@]} files"
    
    if shellcheck "${files[@]}"; then
        echo "[info][shellcheck] successful"
    else
        echo "[info][shellcheck] failed"
    fi
)
