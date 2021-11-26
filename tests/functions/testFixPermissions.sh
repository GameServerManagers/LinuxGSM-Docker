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
# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/../internal/api_docker.sh"
# shellcheck source=tests/internal/api_various.sh
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
    
    if ./tests/quick.sh --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"; then
        permission="$("${dockerRun[@]}" alpine ls -l "$newFile")"
        owner="$("${dockerRun[@]}" alpine ls -l "$newFile")"
        if ! grep -qE '^.rw.r..---' <<< "$permission"; then
            echo "[error][testFixPermissions] new file has wrong permission \"$permission\""
            exit 20
        
        elif ! grep -qE "^[^ ]*\s*[0-9]\s*$uid\s*$gid" <<< "$owner"; then
            echo "[error][testFixPermissions] new file has wrong owner \"$owner\""
            exit 21
        else 
            echo "[testFixPermissions] new file has correct permissions / owner"
        fi 

        permission="$("${dockerRun[@]}" alpine ls -l "lgsm")"
        if ! grep -qE '^.rw.r..---' <<< "$permission"; then
            echo "[error][testFixPermissions] lgsm folder has wrong permission"
            exit 22

        elif [ "0" != "$("${dockerRun[@]}" alpine find "lgsm" ! -user "$uid" | wc -l)" ]; then
            echo "[error][testFixPermissions] lgsm folder / subfile has false uid"
            "${dockerRun[@]}" alpine find "lgsm" ! -user "$uid"
            exit 23
        
        elif [ "0" != "$("${dockerRun[@]}" alpine find "lgsm" ! -group "$gid" | wc -l)" ]; then
            echo "[error][testFixPermissions] lgsm folder / subfile has false gid"
            "${dockerRun[@]}" alpine find "lgsm" ! -group "$gid"
            exit 24
            
        else 
            echo "[testFixPermissions] lgsm folder has correct permissions / owner"
        fi

        permission="$("${dockerRun[@]}" alpine ls -l "$GAMESERVER")"
        owner="$("${dockerRun[@]}" alpine ls -l "$GAMESERVER")"
        if ! grep -qE '^.r.x...---' <<< "$permission"; then
            echo "[error][testFixPermissions] gameserver executable has wrong permission \"$permission\""
            exit 25
        
        elif ! grep -qE "^[^ ]*\s*[0-9]\s*$uid\s*$gid" <<< "$owner"; then
            echo "[error][testFixPermissions] gameserver executable wrong owner \"$owner\""
            exit 26

        else 
            echo "[testFixPermissions] gameserver executable has correct permissions / owner"
        fi 
    else
        echo "[error][testFixPermissions] permissions not fixed and container failed to start"
        exit 10
    fi

    "${dockerRun[@]}" alpine rm "$newFile"
)
