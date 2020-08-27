#!/bin/bash
## linuxgsm-docker base image entrypoint script
## execute LinuxGSM or arbitrary server commands at will
## by passing command

## If you want to use a volume for the data directory, which is the home directory
## then we must keep a backup copy of the script on local drive

if [ -z "${GAMESERVERNAME}" ]; then
    # fail if GAMESERVERNAME env is not specified.
    echo "No game server specificed"
    echo "example: --env GAMESERVERNAME=csgoserver"
elif [ ! -e ~/linuxgsm.sh ]; then
    echo "Initializing LinuxGSM in New Volume"
    cp /linuxgsm.sh ./linuxgsm.sh
    ./linuxgsm.sh ${GAMESERVERNAME}
    ./${GAMESERVERNAME} auto-install
    clear
    ./${GAMESERVERNAME} start
    # to get around LinuxGSM running everything in tmux
    # we attempt to attach to tmux to track the server
    # this keeps the container running
    # when invoked via docker run
    # but requires -it or at least -t
    tmux set -g status off && tmux attach 2> /dev/null
elif [ $# = 0 ]; then 
    ./${GAMESERVERNAME} start
    tmux set -g status off && tmux attach 2> /dev/null
else
    # execute the command passed through docker
    "$@"    
fi

exit 0