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

1. There are prebuild images, if you think you need to build it yourself have a look at [testing readme](./test/testing.md)



  
- `/tests`
  - `steam_test_credentials` some servers need credentials here, currently steam guard is not supported
  - `single.sh` test a single servercode
  - `multiple.sh` test multiple servercodes at once





1. Pick your servercode e.g. `rustserver`
2. Pick ports needed
## Create Persistant Storage
Game servers require persistant storage to store the server files and configs. The docker reccomended way is to use Persistant storage

```
docker volume create csgoserver
```

# Install and Start Game server
```
docker run -d --name csgoserver -v csgoserver --net-host -it -env GAMESERVERNAME=csgoserver gameservermanagers/linuxgsm-docker
```
# Run LinuxGSM commands
Commands can be run just like standard LinuxGSM using the docker exec command.
```
docker exec -it csgoserver ./csgoserver details
```
# Edit LinuxGSM config
To edit the LinuxGSM config files use the following.

View the default settings
```
docker exec -it csgoserver nano _default.cfg
```
Edit LinuxGSM config settings
```
docker exec -it csgoserver nano common.cfg
```
Edit Game Server Config settings
To edit the game server config settings run the following.

```
docker exec -it csgoserver nano server.cfg
```
