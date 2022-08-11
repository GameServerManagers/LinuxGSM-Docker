<h1 align="center">
  <br>
  <a href="https://linuxgsm.com"><img src="https://i.imgur.com/Eoh1jsi.jpg" alt="LinuxGSM"></a>
  LinuxGSM Docker Container
  </h1>

[LinuxGSM](https://linuxgsm.com) is the command-line tool for quick, simple deployment and management of Linux dedicated game servers.

  > This docker image is under development and not officialy supported.

A dockerised version of LinuxGSM https://linuxgsm.com
Dockerhub https://hub.docker.com/r/gameservermanagers/linuxgsm-docker/

## How to use:

1. Choose your servercode and replace in below
2. start `docker-compose -f examples/SERVER.yml up -d`, if the server needs credentials there will be placeholders in the compose.
3. get config location `docker exec -it lgsm-SERVER-1 details`
4. copy your own config into: `docker cp my_local_config.txt lgsm-SERVER-1:/config_location_from_step_3`
5. print config content `docker exec lgsm-SERVER-1 cat /config_location_from_step_3`
6. stop with:
    - Stopping container and keep files `docker-compose -f examples/SERVER.yml down` or `docker stop lgsm-SERVER-1`
    - Stopping container and remove files `docker-compose -f examples/SERVER.yml down --volumes`

## Overview

- build with `./test/single.sh --build-only servercode`
- test with `./test/single.sh servercode`
- get help `./test/single.sh --help`
- LinuxGSM monitor executed every few seconds as health check
- `docker stop CONTAINER` is redirected to lgsm-stop
- `docker logs CONTAINER` show the game server log
- `docker exec -it CONTAINER update` every linuxgsm command is available as long e.g. `lgsm-update` and short e.g. `update` variant. Like `details`, `backup`, `force-update`, ...
- [Repository / Container / Dev structure documentation](DEVELOPER.md)
- [How to build this / How to use it for lgsm testing](test/testing.md)

### How to configure LinuxGSM in docker?

You can configure LinuxGSM and some gameservers(alpha state) with environment variables directly.
E.g. you want to set steamuser / steampass which is a LinuxGSM option:
- `CONFIG_steamuser=...` its checked if this variable exists before its set, container will exit very early if the configuration option isn't already part of _default.cfg
- `CONFIGFORCED_steamuser=...` The variable will be set always, no check done.
- These options will be written to the instance.cfg, thereforce you can use it to set options like `CONFIG_startparameters`, `CONFIG_discordalert` and so on.

### How to use cronjobs?
You can create cron jobs with environment variables. `CRON_update_daily=0 7 * * * update` will create a cronjob which will check for updates once a day. 

### Example ahl2server yml:
```yml
volumes:
  ahl2server-files:

name: lgsm

services:
  ahl2server:
    image: "gameservermanagers/linuxgsm-docker:ahl2server"
    tty: true
    restart: unless-stopped
    environment:
      - "CRON_update_daily=0 7 * * * update"
      - "CONFIGFORCED_steamuser=MySteamName"
      - "CONFIGFORCED_steampass=my steam password"
    volumes:
      - ahl2server-files:/home/linuxgsm
      - /etc/localtime:/etc/localtime:ro
    ports:
      # Game
      - "27015:27015/udp"
      # Query / RCON
      - "27015:27015/tcp"
      # SourceTV
      - "27020:27020/udp"
      # Client
      - "27005:27005/udp"
```
