#!/bin/bash
LGSM_GAMESERVER="$1"
if [ -z "$LGSM_GAMESERVER" ]; then
	echo "[error][createAlias] first argument needs to be target gameserver"
	exit 1
fi

set -o errexit
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi
echo "[info][createAlias] creating linuxgsm alias"

function createAlias() {
	name="$1"
	command="$LGSM_PATH/$LGSM_GAMESERVER"
	file="$LGSM_SCRIPTS/$name"

	if [ -f "$file" ]; then
		echo "[error][createAlias.sh]file already exists => cant create alias with this method"
	else
		echo "[info][createAlias.sh] $command $name"
		cat > "$file" <<- EOM
		#!/bin/sh
		gosu "\$USER_NAME" "$command" "$name" "\$@"
		EOM
		chmod a=rx "$file"
		# create 2nd link for better script readability
		ln -s "$file" "$LGSM_SCRIPTS/lgsm-$name"
	fi
}

#TODO if linuxgsm supports -h / --help to list commands this can be generated
for cmd in install auto-install start stop restart details postdetails backup update-lgsm monitor test-alert update check-update force-update validate console debug \
	change-password map-compressor developer detect-deps detect-glibc detect-ldd query-raw clear-functions; do
	createAlias "$cmd"
done
