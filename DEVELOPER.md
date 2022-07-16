# Overview for developers and consumers of the image

If you want to work on this files at all, check/use: `init_dev_environment.sh`. E.g. it will check for tools you need or prevent your steam credentials to be committed

Repository contains:
- docker build scripts `/build`, sometimes usable by extending dockerimages
- runtime scripts `/runtime`, intended to be used by extending dockerimages and available in PATH
- test scripts `/test`

Please check and use  its telling you if you need to install tools and prevents commiting your steam credentials by accident.

## features

- lgsm commands are available in PATH so you can directly use them e.g. `lgsm-update` which is the same as `update`
- We are using [Gosu](https://github.com/tianon/gosu) so entrypoint is executed as root but every command is executed with lower user privilege.
  - Because the commands take care of gosu, you can use `lgsm-update` in your custom scripts as root and the command will take care of correct user
  - Also works if you are using: `docker exec -it CONTAINER update`
- `/runtime` contains scripts(refered to as commands of the image) which provide standard functions, also available in PATH so you can directly invoke them
  - `lgsm-fix-permission` resets all file permissions in volume
  - `lgsm-update-uid-gid` update uid / gid of lgsm user and all owned files 
  - `lgsm-init` resets linuxgsm.sh in volume and installs _servercode_.sh
  - Cron job handling via Supercronic `lgsm-cron-init` `lgsm-cron-start`
- _alpha state_ `lgsm-load-config` updates gameconfig according to environment variables

## dockerimage folder structure

- `/home/linuxgsm/`
    - home folder of linuxgsm user
    - volume for linuxgsm installation
- `/home/linuxgsm-scripts`
    - contains all scripts and links and is part of PATH variable, so all scripts are directly accessible from everywhere
        - initial linuxgsm.sh
        - links to lgsm commands like `lgsm-monitor` which is identical to `monitor`

