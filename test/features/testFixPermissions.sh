#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# assuming volume is initialized!
VERSION="$1"
GAMESERVER="$2"
VOLUME="$3"
uid="750"
gid="750"
# shellcheck source=test/internal/api_docker.sh
source "$(dirname "$0")/../internal/api_docker.sh"
# shellcheck source=test/internal/api_various.sh
source "$(dirname "$0")/../internal/api_various.sh"

(
    cd "$(dirname "$0")/../.."

    # test volume change
    newFile="newFile.test"
    dockerRun=(docker run -it --rm -v "$VOLUME:/home" --workdir "/home")
    # new file in volume with wrong owner
    "${dockerRun[@]}" -u root:root alpine touch "$newFile"
    # existing folder changed ownership
    "${dockerRun[@]}" -u root:root alpine chown -R 1234:5678 "lgsm"
    # server executable with false permissions
    "${dockerRun[@]}" alpine chmod ugo= "$GAMESERVER"

    function log() {
        if [ -n "${2:-}" ]; then
            echo "[error][testFixPermissions] $1"
            echo "${3:-}"
            exit "$2"
        else
            echo "[info][testFixPermissions] $1"
        fi
    }
    
    if ./test/single.sh --very-fast --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"; then
        permission="$("${dockerRun[@]}" alpine ls -l "$newFile")"
        owner="$("${dockerRun[@]}" alpine ls -l "$newFile")"
        if ! grep -qE '^.rw.r..---' <<< "$permission"; then
            log "new file has wrong permission \"$permission\"" 20
        
        elif ! grep -qE "^[^ ]*\s*[0-9]\s*$uid\s*$gid" <<< "$owner"; then
            log "new file has wrong owner \"$owner\"" 21
        else 
            log "new file has correct permissions / owner"
        fi 

        permission="$("${dockerRun[@]}" alpine ls -l "lgsm")"
        if ! grep -qE '^.rw.r..---' <<< "$permission"; then
            log "lgsm folder has wrong permission" 22

        elif [ "0" != "$("${dockerRun[@]}" alpine find "lgsm" ! -user "$uid" | wc -l)" ]; then
            log "lgsm folder / subfile has false uid" 23 "$("${dockerRun[@]}" alpine find "lgsm" ! -user "$uid" | tail)"
        
        elif [ "0" != "$("${dockerRun[@]}" alpine find "lgsm" ! -group "$gid" | wc -l)" ]; then
            log "lgsm folder / subfile has false gid" 24 "$("${dockerRun[@]}" alpine find "lgsm" ! -group "$gid" | tail)"
            
        else 
            log "lgsm folder has correct permissions / owner"
        fi

        permission="$("${dockerRun[@]}" alpine ls -l "$GAMESERVER")"
        owner="$("${dockerRun[@]}" alpine ls -l "$GAMESERVER")"
        if ! grep -qE '^.r.x...---' <<< "$permission"; then
            log "gameserver executable has wrong permission \"$permission\"" 25
        
        elif ! grep -qE "^[^ ]*\s*[0-9]\s*$uid\s*$gid" <<< "$owner"; then
            log "gameserver executable wrong owner \"$owner\"" 26

        else 
            log "gameserver executable has correct permissions / owner"
        fi 
    else
        log "permissions not fixed and container failed to start" 10
    fi

    "${dockerRun[@]}" alpine rm "$newFile"
)
