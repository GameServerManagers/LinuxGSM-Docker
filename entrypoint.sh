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
    wget https://linuxgsm.com/dl/linuxgsm.sh -O ~/linuxgsm.sh && chmod +x ~/linuxgsm.sh
fi

# with no command, just run the game (or try)
if [ $# = 0 ]; then
    if [ ! -e "$GAMESERVER" ]; then
        echo "Installing $GAMESERVER"
        ./linuxgsm.sh "$GAMESERVER" && "./$GAMESERVER" auto-install
    fi
    echo "Launching $GAMESERVER (IN DEBUG MODE)"
    echo Y | "./$GAMESERVER" debug
else
    # execute the command passed through docker
    "$@"
fi
