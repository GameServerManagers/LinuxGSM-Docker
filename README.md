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

## Details

- build with:
  - `./test/single.sh --build-only servercode`
  - `./test/single.sh --help`

- [Repository / Container / Dev structure documentation](DEVELOPER.md)
- [How to build this / How to use it for lgsm testing](test/testing.md)
