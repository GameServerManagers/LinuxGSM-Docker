#!/bin/bash

set -euo pipefail

folder="${1:?}"
code="${2:-""}"

mapfile -t results < <(find "$folder" -type f -iname "*.log" | sort)
for log in "${results[@]}"; do
    if [ -z "$code" ] || grep -qe "$code." <<< "$log"; then
        echo ""
        echo "$log:10000"
        grep -Poe '(?<="Output": ").*' "$log" | sed -E 's/u001b\[[0-9a-z ]*//g' | sed 's/\\r/\n/g' | sed 's/\\n/\n/g' || true
    fi
done
