#!/bin/bash

LGSM_SERVER="$1"
readonly LGSM_SERVER

set -o errexit
set -o pipefail
set -o nounset

cd "$LGSM_PATH"

## linuxgsm-docker base image entrypoint script
## execute LinuxGSM or arbitrary server commands at will
## by passing command

# uid / gid mod
# fix permissions
./../setupUser.sh

## Because of a limitation in LinuxGSM script it must be run from the directory
## It is installed in.
##
## If one wants to use a volume for the data directory, which is the home directory
## then we must keep a backup copy of the script on local drive
if [ "$#" = "0" ]; then
    echo "[entrypoint] please provide server as first argument"
    exit 1
elif [ ! -e ~/"$LGSM_SERVER" ]; then
    echo "installing $LGSM_SERVER"
    gosu "$USER_NAME" cp -f /home/linuxgsm.sh ./linuxgsm.sh
    gosu "$USER_NAME" ./linuxgsm.sh "$LGSM_SERVER"

    # check if server can be installed
    gosu "$USER_NAME" ./"$LGSM_SERVER" auto-install 2>&1 | tee auto-install.log
    # if not probably dependencies are missing
    IFS=';' cmds=($(grep 'sudo\s*dpkg' auto-install.log | sed -E 's/\s*sudo\s*//g' | sed 's/install/install -y /g'))
    if [ "${#cmds[@]}" -gt "0" ]; then
        # preselect answers for steam
        echo steam steam/question select "I AGREE" | debconf-set-selections
        echo steam steam/license note '' | debconf-set-selections

        # install dependencies
        for cmd in "${cmds[@]}"; do
            eval "DEBIAN_FRONTEND=noninteractive $cmd"
        done
        # retry
        gosu "$USER_NAME" ./"$LGSM_SERVER" auto-install
    fi
    
fi

exec gosu "$USER_NAME" ./"$LGSM_SERVER" "start"
