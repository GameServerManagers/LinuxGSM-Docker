# Overview for developers and consumers of the image

Repository contains:
- docker build scripts `/build`
- runtime scripts `/runtime`
- test scripts `/test`

## repository folder structure

- `/runtime` runtime functionality intended to be used by extending dockerimages and available in PATH
  - refered as `commands` of the dockerimage
  - `lgsm-update-uid-gid` update uid / gid of lgsm user and all owned files
  - `lgsm-fix-permission` resets all file permissions in volume
  - `lgsm-init` resets linuxgsm.sh in volume and install _servercode_.sh
  - `lgsm-cron-init`
  - `lgsm-cron-start`
  - `lgsm-tmux-attach`
  - `lgsm-COMMAND` and `COMMAND` where command is an available lgsm command, e.g. details, monitor, install, aso.
  - `lgsm-load-config` _alpha state_ updates gameconfig according to environment variables
  
- `/build` build functionionality sometimes usable by extending dockerimages
  - `installMinimalDependencies.sh` install minimal dependencies needed for build / runtime scripts
  - `cleanImage.sh` clean and shrink dockerimage, e.g. remove apt cache and build scripts
  - `entrypoint.sh` entrypoint for linuxgsm images, also example how the commands can be used. Expected to be executed as root with access to gosu.
  - `setupUser.sh` create linuxgsm user
  - `createAlias.sh` creates all alias for `lgsm-COMMAND` and `COMMAND`
  - `installDependencies.sh` use linuxgsm to install needed dependencies
  - `installGamedig.sh` install nodejs and recent gamedig
  - `installGosu.sh` install Gosu to `/usr/local/bin/gosu`
  - `installOpenSSL_1.1n.sh`
  - `installLGSM.sh`

## dockerimage folder structure

- `/home/linuxgsm/`
    - home folder of linuxgsm user
    - volume for linuxgsm installation
- `/home/linuxgsm-scripts`
    - contains all scripts and links and is part of PATH variable, so all scripts are directly accessible from everywhere
        - initial linuxgsm.sh
        - links to lgsm commands like `lgsm-monitor` which is identical to `monitor`