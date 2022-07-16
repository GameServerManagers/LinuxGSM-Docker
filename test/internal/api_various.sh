#!/bin/bash

function isEmpty() {
    [ -z "$1" ]
}

function contains() {
    echo "$1" | grep -qF "$2"
}

function getServerList() {
    linuxgsm_version="$1"
    working_folder="$(mktemp -d)"
    (
        cd "$working_folder" > /dev/null 2>&1 || exit 1
        wget -O "linuxgsm.sh" "https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/$linuxgsm_version/linuxgsm.sh" > /dev/null 2>&1
        chmod +x "linuxgsm.sh" > /dev/null 2>&1
        ./linuxgsm.sh list | grep -vE '^fetching'
        rm -rf "$working_folder" > /dev/null 2>&1
    )
}

function getServerCodeList() {
    getServerList "$1" | grep -oE '^\S*'
}

function sed_sanitize() {
    local sanitized="$1"
    local sanitized="${sanitized//\\/\\\\}"  # \ need to be escaped e.g. 's/\//'
    local sanitized="${sanitized//\//\\/}"   # / need to be escaped e.g. 's///'
    #local sanitized="${sanitized//\{/\\\\{}" # { need to be escaped
    local sanitized="${sanitized//[/\\[}"    # [ need to be escaped
    local sanitized="${sanitized//&/\\&}"    # & need to be escaped
    local sanitized="${sanitized//\*/\\\*}"    # * need to be escaped
    echo "$sanitized"
}