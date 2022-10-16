#!/bin/bash

exit_handler () {
    # Execute the  shutdown commands
    [ -z "${GAMESERVER_INSTANCE}" ] && echo "recieved SIGTERM stopping ${GAMESERVER}" || echo "recieved SIGTERM stopping ${GAMESERVER}${GAMESERVER_INSTANCE}"
    [ -z "${GAMESERVER_INSTANCE}" ] && ./${GAMESERVER} stop || ./${GAMESERVER}${GAMESERVER_INSTANCE} stop
    exit 0
}

# Exit trap
echo "loading exit trap"
trap exit_handler SIGTERM

echo -e "Welcome to the LinuxGSM Docker"
echo -e "================================================================================"
echo -e "GAMESERVER: ${GAMESERVER}"
[ -n "${GAMESERVER_INSTANCE}" ] && echo -e "GAMESERVER INSTANCE: ${GAMESERVER_INSTANCE}"
echo -e "UID: $UID"
echo -e ""
echo -e "LGSM_GITHUBUSER: ${LGSM_GITHUBUSER}"
echo -e "LGSM_GITHUBREPO: ${LGSM_GITHUBREPO}"
echo -e "LGSM_GITHUBBRANCH: ${LGSM_GITHUBBRANCH}"

echo -e ""
echo -e "Initalising"
echo -e "================================================================================"
# Correct permissions in home dir
echo "update permissions for linuxgsm"
sudo chown -R linuxgsm:linuxgsm /home/linuxgsm

# Copy linuxgsm.sh into homedir
if [ ! -e ~/linuxgsm.sh ]; then
    echo "copying linuxgsm.sh to /home/linuxgsm"
    cp /linuxgsm.sh ~/linuxgsm.sh
fi

# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
    echo "creating ./${GAMESERVER}"
    ./linuxgsm.sh ${GAMESERVER}
fi

# Create game server instance

if [  -n  "${GAMESERVER_INSTANCE}" ]; then
    echo "renaming ${GAMESERVER} to ${GAMESERVER}${GAMESERVER_INSTANCE}"
    mv ${GAMESERVER} ${GAMESERVER}${GAMESERVER_INSTANCE}
fi

# Install game server
if [ -z "$(ls -A -- "serverfiles")" ]; then
    [ -z "${GAMESERVER_INSTANCE}" ] && echo "installing ${GAMESERVER}" || echo "installing ${GAMESERVER}${GAMESERVER_INSTANCE}"
    [ -z "${GAMESERVER_INSTANCE}" ] && ./${GAMESERVER} auto-install || ./${GAMESERVER}${GAMESERVER_INSTANCE} auto-install
fi

echo "starting cron"
sudo cron

# Update game server
echo ""
[ -z "${GAMESERVER_INSTANCE}" ] && echo "update ${GAMESERVER}" || echo "update ${GAMESERVER}${GAMESERVER_INSTANCE}"
[ -z "${GAMESERVER_INSTANCE}" ] && ./${GAMESERVER} update || ./${GAMESERVER}${GAMESERVER_INSTANCE} update

echo ""
[ -z "${GAMESERVER_INSTANCE}" ] && echo "start ${GAMESERVER}" || echo "start ${GAMESERVER}${GAMESERVER_INSTANCE}"
[ -z "${GAMESERVER_INSTANCE}" ] && ./${GAMESERVER} start || ./${GAMESERVER}${GAMESERVER_INSTANCE} start
sleep 5
[ -z "${GAMESERVER_INSTANCE}" ] && ./${GAMESERVER} details || ./${GAMESERVER}${GAMESERVER_INSTANCE} details

tail -f log/script/*

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

exec "$@"
