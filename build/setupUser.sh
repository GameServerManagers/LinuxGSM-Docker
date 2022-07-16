#!/bin/sh

# create linuxgsm user

set -o errexit
set -o nounset
if "$LGSM_DEBUG"; then
    set -o xtrace
fi
GROUP_NAME="$USER_NAME"

# create it
groupadd -g "$GROUP_ID" -o "$GROUP_NAME"
adduser --home "$LGSM_PATH" --uid "$USER_ID" --disabled-password --gecos "" --ingroup "$GROUP_NAME" "$USER_NAME"
usermod -G tty "$GROUP_NAME"

# enforce correct permissions
chown -R "$USER_NAME:$GROUP_NAME" "$LGSM_PATH"
chmod 755 "$LGSM_PATH"
