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

# check if uid / guid should be changed
GROUP_NAME="$USER_NAME"
if [ "$(id --user "$USER_ID")" != "$USER_ID" ] || [ "$(id --group "$USER_ID")" != "$GROUP_ID" ]; then
    echo "[setupUser] changing user id"
    old_user_id="$(id --user "$USER_ID")"
    usermod -u "$USER_ID" "$USER_NAME"
    find / -uid "$old_user_id" -exec chown "$USER_NAME" "{}" \;

    echo "[setupUser] changing group id"
    old_group_id="$(id --group "$USER_ID")"
    groupmod -g "$GROUP_ID" "$GROUP_NAME"
    find / -gid "$old_group_id" -exec chown ":$USER_NAME" "{}" \;
fi

# enforce correct permissions
chown -R "$USER_NAME:$GROUP_NAME" "$LGSM_PATH"
chmod 755 "$LGSM_PATH"

# check if wished server is provided
if [ "$#" = "0" ]; then
    echo "[entrypoint] please provide server as first argument"
    exit 1
# check if server is already installed
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
        echo steam steam/question select "I AGREE" | debconf-set-selections #"# ide fix
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
