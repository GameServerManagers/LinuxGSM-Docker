# LinuxGSM Docker

This is under development and not officialy supported yet. However feel free to try it and submit improvements

A docker container distribution of https://github.com/GameServerManagers/LinuxGSM

Dockerhub https://hub.docker.com/r/gameservermanagers/linuxgsm-docker/

Run Game Servers in Docker, multiplex multiple LinuxGSM deployments easily by taking advantage of Dockers port mapping.

## Easy step

The script create a user name lgsm with a home directory path /home/lgsm/

Use root user of the main linux system to build and use the script

- Download the git repo git clone ...
- Change permission to executable : chmod +x linuxgsm-docker-build.sh && chmod +x linuxgsm-docker.sh
- Edit DockerFile and open the proper Ports for the server type you want to install(default steam base 777[7-8], 2015...)
- Execute linuxgsm-docker-build.sh
- Edit some variable at the top of the linuxgsm-docker.sh script
- Execute linuxgsm-docker.sh all you need is in this script

if you want to edit server config from main linux system you need to have lgsm user as the same uid than in docker for the user or the owner ship going to be diffrent in container and the main linux system get permission issue or need to chown it but you can't do that from the main linux system because the user for the chown is on a other os...


### After this line the documentation is out updated but most of it is usefull

## Image Tags

- `latest` `base` - base image with linuxgsm.sh script and user setup
  base image can be used to install any server
- *`servername`* - convenience images with preinstalled game servers

## Usage Docker

The base image is just a dockerized environment to run `linuxgsm.sh`. As such it can be used as though its on a local install that is, to list the available servers

`docker run --rm akshmakov/linuxgsm:base linuxgsm list`

in general any command can be executed.

If no command is passed, the container will not exit allowing `docker exec` to be used to execute commands


### Base Image

Lets  build up a local server using just the base image

We will mount the host directory `/srv/lgsm/server1` to the container folder `/home/lgsm` , this will persist all GSM data on the host.

User ID mapping with containers is not-trivial, so this tutorial will use `chmod` workaround for quick host mounted volumes, but this is not ideal.

```
# create the host folder
$ mkdir -p /srv/lgsm/server1 && chmod 777 /srv/lgsm/server1
```

```
# start the server environment into a shell
$ docker run --rm -it -v "/srv/lgsm/server1:/home/lgsm" akshmakov/linuxgsm:base bash
```

```
# install quake 3 arena server
$ linuxgsm q3server
$ q3server install
# exit the shell
$ exit
```

The server is now built up, you can edit the config files from the host or within a shell
in the container.

All that is left is to start the server, in this case, q3server uses port 27960 so we will publish it.


```
# start the server with port publishing and docker logging
$ docker run --name quake3  -t -d -p "27960:27960" -v "/srv/lgsm/server1:/home/lgsm" akshmakov/linuxgsm:base q3server start
```
**Note:** the `-t` is  **required** due to the way linuxgsm works

```
# check the logs
$ docker logs quake3
```

```
# open a shell on the container to inspect or modify
$ docker exec -it quake3 bash
```

You can repeat the process to install another gameserver on the same host, make sure to change the published port if you are installing multiple copies of the same gameserver.


### Specific Image

These images are predownloaded versions of the LinuxGSM server library in docker containers.

These images are taged on dockerhub as `akshmakov/linuxgsm:SERVERNAME`

The images can be run without a command, which by default will start a server

These images are best to be extended, as the server data will be overwritten by any mounted volume


``` Dockerfile
FROM akshmakov/linuxgsm:$SERVERNAME

COPY myserverconfig.cfg /home/lgsm/lgsm/config-lgsm/$SERVERNAME/$SERVERNAME.cfg
```

then any extended image may be run as such

```
# build the custom image
$ docker build -tag local/linuxgsm:$SERVERNAME .
sudo docker run --name arkserver --rm -it -d -v "/home/lgsm/:/home/lgsm" lgsm-docker bash# start the server
$ docker run -d --name my-custom-server local/linuxgsm:$SERVERNAME 
```

**NOTE:** -t tag not necessary for the specific images

## Usage Docker-Compose

Docker-compose can be used to manage multiple installations.


``` docker-compose.yml

version: '2'

services:

  # Pre-setup "base image" (see above)
  # Or an installation copied from an existing server
  q3server-1:
    image: akshmakov/linuxgsm:base
    volumes:
      - '/srv/lgsm/q3server-1:/home/lgsm'
    ports:
      - '27960:27960
    tty: true

  ## specific image - no customization
  ## Running on alt port
  q3server-2:
    image: akshmakov/linuxgsm:q3server
    ports:
      - '27961:27960'
    tty: true

  ## custom specific image
  ## assume Dockerfile for this server exists
  ## in local dir
  q2server:
    build:
      dockerfile: Dockerfile.q2server
    image: local/linuxgsm:q2server
    ports:
      - '27910:27910'
    tty: true
```

You can start the whole cluster

```
$ docker-compose up -d
```

Examine specific logs

```
$ docker-compose logs q2server
```

Take one down and leave the others running

```
$ docker-compose stop q2server
```


## Container Overview

`linuxgsm-docker.sh` script is particularly picky about paths and does things a little different from a typical daemon.

In particular this docker images seeks to encapsulate LinuxGSM exactly as it is, to allow for easy transition from non-docker based deployments

These quirks are

- Script downloads a whole bunch of other script components (hard to track docker cache)
- Script installs game servers in script install dir (hard to relocate)
- Script refuses to run as root (Requires image have users added and permissions granted)
- Script runs server in a tmux session (Difficult to attach to output)


This Container runs `linuxgsm.sh`  under a generic user `lgsm` and script and server data installed under the home directory `/home/lgsm`



