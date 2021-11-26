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
    ./tests/quick.sh --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"

    dockerRun=(docker run -it --rm -v "$VOLUME:/home" --workdir "/home")
    if [ "0" != "$("${dockerRun[@]}" alpine find . ! -user "$uid" ! -iname "tmux.pipe" | wc -l )" ]; then
        echo "[testUpdateUidGuid] precondition failed, there are files in \"$VOLUME\" which aren't owned by user \"$uid\""
        "${dockerRun[@]}" alpine find . ! -user "$uid" ! -iname "tmux.pipe" | tail
        exit 20

    elif [ "0" != "$("${dockerRun[@]}" alpine find . ! -group "$gid" ! -iname "tmux.pipe" | wc -l )" ]; then
        echo "[testUpdateUidGuid] precondition failed, there are files in \"$VOLUME\" which aren't owned by group \"$gid\""
        "${dockerRun[@]}" alpine find . ! -group "$gid" ! -iname "tmux.pipe" | tail
        exit 21
        
    else
       echo "[testUpdateUidGuid] precondition successful"
    fi

    ./tests/quick.sh --version "$VERSION" --volume "$VOLUME" "$GAMESERVER" -e "USER_ID=1234" -e "GROUP_ID=5678"
    if [ "0" != "$("${dockerRun[@]}" alpine find . ! -user "1234" ! -iname "tmux.pipe" | wc -l )" ]; then
        echo "[testUpdateUidGuid] update failed, there are files in \"$VOLUME\" which aren't owned by user \"1234\""
        "${dockerRun[@]}" alpine find . ! -user "1234" ! -iname "tmux.pipe" | tail
        exit 22

    elif [ "0" != "$("${dockerRun[@]}" alpine find . ! -group "5678" ! -iname "tmux.pipe" | wc -l )" ]; then
        echo "[testUpdateUidGuid] update failed, there are files in \"$VOLUME\" which aren't owned by group \"5678\""
        "${dockerRun[@]}" alpine find . ! -group "5678" ! -iname "tmux.pipe" | tail
        exit 23
        
    else
       echo "[testUpdateUidGuid] update successful"
    fi

    echo "[testUpdateUidGuid] resetting permissions"
    "${dockerRun[@]}" alpine chown -R "$uid:$gid" .
)
