#!/bin/bash
## linuxgsm-docker base image entrypoint script
## execute LinuxGSM or arbitrary server commands at will
## by passing command

## If you want to use a volume for the data directory, which is the home directory
## then we must keep a backup copy of the script on local drive

fn_container_run(){
# with no command, just spawn a running container suitable for exec's
if [ $# = 0 ]; then
    tail -f /dev/null
else
    # execute the command passed through docker
    "$@"

    # if the command is start
    # to get around LinuxGSM running everything in
    # tmux;
    # we attempt to attach to tmux to track the server
    # this keeps the container running
    # when invoked via docker run
    # but requires -it or at least -t
    tmux set -g status off && tmux attach 2> /dev/null
fi
}

if [ ! -e ~/linuxgsm.sh ]; then
    echo "Initializing LinuxGSM in New Volume"
    cp /linuxgsm.sh ./linuxgsm.sh
    ./linuxgsm.sh ${GAMESERVERNAME}
    ./${GAMESERVERNAME} auto-install
    fn_container_run
    ./${GAMESERVERNAME} start
else
    fn_container_run  
fi


exit 0