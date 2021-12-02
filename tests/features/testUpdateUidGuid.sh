#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="$1"
GAMESERVER="$2"
VOLUME="$3"
uid="750"
gid="750"

(
    cd "$(dirname "$0")/../.."
    ./tests/quick.sh --very-fast --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"

    function log() {
        if [ -n "${2:-}" ]; then
            echo "[error][testUpdateUidGuid] $1"
            echo "${3:-}"
            exit "$2"
        else
            echo "[info][testUpdateUidGuid] $1"
        fi
    }

    dockerRun=(docker run -it --rm -v "$VOLUME:/home" --workdir "/home")
    if [ "0" != "$("${dockerRun[@]}" alpine find . ! -user "$uid" ! -iname "tmux.pipe" | wc -l )" ]; then
        log "precondition failed, there are files in \"$VOLUME\" which aren't owned by user \"$uid\"" 20 "$("${dockerRun[@]}" alpine find . ! -user "$uid" ! -iname "tmux.pipe" | tail)"

    elif [ "0" != "$("${dockerRun[@]}" alpine find . ! -group "$gid" ! -iname "tmux.pipe" | wc -l )" ]; then
        log "precondition failed, there are files in \"$VOLUME\" which aren't owned by group \"$gid\"" 21 "$("${dockerRun[@]}" alpine find . ! -group "$gid" ! -iname "tmux.pipe" | tail)"

    else
       log "precondition successful"
    fi

    ./tests/quick.sh --very-fast --version "$VERSION" --volume "$VOLUME" "$GAMESERVER" -e "USER_ID=1234" -e "GROUP_ID=5678"
    if [ "0" != "$("${dockerRun[@]}" alpine find . ! -user "1234" ! -iname "tmux.pipe" | wc -l )" ]; then
        log "update failed, there are files in \"$VOLUME\" which aren't owned by user \"1234\"" 22 "$("${dockerRun[@]}" alpine find . ! -user "1234" ! -iname "tmux.pipe" | tail)"

    elif [ "0" != "$("${dockerRun[@]}" alpine find . ! -group "5678" ! -iname "tmux.pipe" | wc -l )" ]; then
        log "update failed, there are files in \"$VOLUME\" which aren't owned by group \"5678\"" 23 "$("${dockerRun[@]}" alpine find . ! -group "5678" ! -iname "tmux.pipe" | tail)"

    else
       log "update successful"
    fi

    log "resetting permissions"
    "${dockerRun[@]}" alpine chown -R "$uid:$gid" .
)
