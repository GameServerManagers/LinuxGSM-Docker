#!/bin/bash

server="$1"
set -o errexit
set -o pipefail
set -o nounset
echo "[info][installDependencies] installing $server"
cd "$LGSM_PATH"
gosu "$USER_NAME" cp -f "$LGSM_SCRIPTS/linuxgsm.sh" .
gosu "$USER_NAME" ./linuxgsm.sh "$server"

# check if server can be installed
# TODO currently this is the only way to recognize if new dependencies are needed
# maybe add a "./linuxgsm.sh installDependencies"
gosu "$USER_NAME" ./"$server" auto-install 2>&1 | tee auto-install.log || true
# if not probably dependencies are missing
mapfile -d ";" cmds < <( grep 'sudo\s*dpkg' auto-install.log | sed -E 's/\s*sudo\s*//g' | sed 's/install/install -y /g' )
if [ "${#cmds[@]}" -gt "0" ]; then
    # preselect answers for steam
    echo steam steam/question select "I AGREE" | debconf-set-selections #"# ide fix
    echo steam steam/license note '' | debconf-set-selections

    # install dependencies
    echo "[info][installDependencies] installing dependencies:"
    for cmd in "${cmds[@]}"; do
        echo "$cmd"
        eval "DEBIAN_FRONTEND=noninteractive $cmd" || (
            apt-get update
            eval "DEBIAN_FRONTEND=noninteractive $cmd"
        )
    done
fi
