#!/bin/bash

# creates all alias for `lgsm-COMMAND` and `COMMAND` in /home/linuxgsm-scripts($LGSM_SCRIPTS) which are available in PATH

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
	name="$(tr '[:upper:]' '[:lower:]' <<< "$1")"
	command="$LGSM_PATH/$LGSM_GAMESERVER"
	file="$LGSM_SCRIPTS/$name"

	if [ -f "$file" ]; then
		echo "[error][createAlias.sh]file already exists => cant create alias with this method"
	else
		echo "[info][createAlias.sh] $command $name"
		cat > "$file" <<- EOM
		#!/bin/sh
		echo '$name' >> "\$LGSM_CURRENT_COMMAND"
		gosu "\$USER_NAME" "$command" "$name" "\$@"
		exitcode="\$?"
		sed -i '/^$name$/d' "\$LGSM_CURRENT_COMMAND"
		exit "\$exitcode"
		EOM
		chmod a=rx "$file"
		# create 2nd link for better script readability
		ln -s "$file" "$LGSM_SCRIPTS/lgsm-$name"
	fi
}

lgsm-init
(
	cd "$LGSM_PATH"

	help_command="$LGSM_SCRIPTS/lgsm-help"
	printf '%s\n%s' '#!/bin/bash' > "$help_command"
	chmod +x "$help_command"
	ln -s "$help_command" "$LGSM_SCRIPTS/--help"
	ln -s "$help_command" "$LGSM_SCRIPTS/-h"

	# IMPORTANT: assuming ./server will provide commands in format "[ddmlong\s+short\s+| description" # TODO lgsm supporting --help, best unformated
	mapfile -t commands < <(gosu "$USER_NAME" ./"$LGSM_GAMESERVER" | grep -Eo '\[[0-9]+m[a-zA-Z_]+[^|]+\|.*' | sed -E 's/\[[0-9]+m//')
	for command in "${commands[@]}"; do
		name="$(echo "$command" | grep -o '^[^ ]*')"
		description="$(echo "$command" | grep -o '[^|]*$')"
		createAlias "${name}"
		printf "echo '%-40s| %s'\n" "$name lgsm-$name" "$description" >> "$help_command"
	done
)
