#!/bin/bash
## linuxgsm-docker base image entrypoint script
## execute LinuxGSM or arbitrary server commands at will
## by passing command


## Because of a limitation in LinuxGSM script it must be run from the directory
## It is installed in.
##
## If one wants to use a volume for the data directory, which is the home directory
## then we must keep a backup copy of the script on local drive
if [ ! -e ~/linuxgsm.sh ]; then
    echo "Initializing Linuxgsm User Script in New Volume"
    cp /linuxgsm.sh ./linuxgsm.sh
fi

# with no command, just spawn a running container suitable for exec's
if [ $# = 0 ]; then
    tail -f /dev/null
else
    # execute the command passed through docker
    "$@"

    # if this command was a server start cmd
    # to get around LinuxGSM running everything in
    # tmux;
    # we attempt to attach to tmux to track the server
    # this keeps the container running
    # when invoked via docker run
    # but requires -it or at least -t
    tmux set -g status off && tmux attach 2> /dev/null
fi

exit 0
