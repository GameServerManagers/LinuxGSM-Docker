#!/bin/bash

server="$1"
set -o errexit
set -o pipefail
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi
echo "[info][installDependencies] installing $server"
cd "$LGSM_PATH"
gosu "$USER_NAME" cp -f "$LGSM_SCRIPTS/linuxgsm.sh" .
gosu "$USER_NAME" ./linuxgsm.sh "$server"

# check if server can be installed
# TODO currently this is the only way to recognize if new dependencies are needed
# maybe add a "./linuxgsm.sh installDependencies"
gosu "$USER_NAME" ./"$server" auto-install 2>&1 | tee auto-install.log || true
# if not probably dependencies are missing
mapfile -t cmds < <( grep -Eoe 'sudo\s\s*apt\S*\s\s*install.*' auto-install.log | sed -E 's/\s*sudo\s*//g' | sed 's/install/install -y /g' | tr ';' '\n' )
if [ "${#cmds[@]}" -gt "0" ]; then
    # preselect answers for steam
    echo steam steam/question select "I AGREE" | debconf-set-selections #"# ide fix
    echo steam steam/license note '' | debconf-set-selections

    # install dependencies
    echo "[info][installDependencies] installing dependencies:"
	if grep -qe ':i386' <<< "${cmds[@]}"; then
		dpkg --add-architecture i386
	fi
	apt-get update
	set -x
    for cmd in "${cmds[@]}"; do
        echo "[info][installDependencies] >$cmd<"
		if eval "DEBIAN_FRONTEND=noninteractive $cmd"; then
			echo "[info][installDependencies] successful!"
		else
			echo "[error][installDependencies] failed"
			exit 10
		fi
    done
else
	echo "[error][installDependencies] Couldn't extract missing dependencies, its very unlikely that everything is already installed. Printing debug information:"
	echo "${cmds[@]}"
	cat auto-install.log
	exit 10
fi
