#!/bin/sh

set -o errexit
set -o nounset
GROUP_NAME="$USER_NAME"

# if user doesn't exit
if ! id --user "$USER_ID" > /dev/null 2>&1; then
    # create it
    groupadd -g "$GROUP_ID" -o "$GROUP_NAME"
    adduser --home "$LGSM_PATH" --uid "$USER_ID" --disabled-password --gecos "" --ingroup "$GROUP_NAME" "$USER_NAME"
    usermod -G tty "$GROUP_NAME"

# if user/group has incorrect id
elif [ "$(id --user "$USER_ID")" != "$USER_ID" ] || [ "$(id --group "$USER_ID")" != "$GROUP_ID" ]; then
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
