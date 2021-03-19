## DOCKER COMPOSE DRAFT

# Overview
The docker image dockclair/lgsm-dev has been modified for use with docker-compose by adding a bootstrap-like sh script.

For this to work the environment variable 'GAMESERVER' needs to be set and match
a valid (supported) LinuxGSM server.

All questions posed to the user will be answered with the default 'yes'

# Issues
No PID 1 constantly running for the container to remain up even with -d or the entrypoint's use of tmux. We need a process to remain running as PID 1 so it doesn't die immediately after starting the game server.
