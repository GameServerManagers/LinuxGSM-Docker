#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

#VERSION="$1"
GAMESERVER="$2"
VOLUME="$3"
CONTAINER="linuxgsm-$GAMESERVER-testCron"
# shellcheck source=test/internal/api_docker.sh
source "$(dirname "$0")/../internal/api_docker.sh"

(
    cd "$(dirname "$0")/../.."
    DOCKERFILE_CRONLOCATION="$(grep -Po '(?<=SUPERCRONIC_CONFIG=")[^"]*' Dockerfile)"


    function fn_exit() {
        removeContainer "$CONTAINER"
        exit "${1:-1}"
    }
    trap fn_exit SIGTERM SIGINT

    function log() {
        if [ -n "${2:-}" ]; then
            echo "[error][testCron] $1"
            fn_exit "$2"
        else
            echo "[info][testCron] $1"
        fi
    }

       # initial run = no cron
    removeContainer "$CONTAINER"
    ./test/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER"
    if awaitHealthCheck "$CONTAINER"; then
        if [ "0" != "$(docker exec -it "$CONTAINER" cat "$DOCKERFILE_CRONLOCATION" | wc -l)" ]; then
            log "successful no cron job found"
        else
            log "container shouldn't have a cronjob" 20
        fi
    else
        log "container is unhealthy" 10
    fi

    # inject one cron
    CRON_TEST1="* * * * * echo \"hello world1\""
    removeContainer "$CONTAINER"
    ./test/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" "-e" "CRON_test1=$CRON_TEST1"
    if awaitHealthCheck "$CONTAINER"; then
        crontab="$(docker exec -it "$CONTAINER" cat "$DOCKERFILE_CRONLOCATION")"
        if [ "2" != "$(echo "$crontab" | wc -l)" ]; then
            log "expected two cron lines, found $(echo "$crontab" | wc -l)" 21
        elif ! grep -qE "^$CRON_TEST1" <<< "$crontab"; then
            log "provided crontab isn't part of container but should be" 22
        else
            log "successfully tested one cronjob"
        fi
    else
        log "container is unhealthy" 11
    fi

    # inject multiple cron
    CRON_TEST2="* * * * * echo \"hello world2\""
    removeContainer "$CONTAINER"
    ./test/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" "-e" "CRON_test1=$CRON_TEST1" "-e" "CRON_test2=$CRON_TEST2"
    if awaitHealthCheck "$CONTAINER"; then
        crontab="$(docker exec -it "$CONTAINER" cat "$DOCKERFILE_CRONLOCATION")"
        if [ "3" != "$(echo "$crontab" | wc -l)" ]; then
            log "expected 3 cron lines, found $(echo "$crontab" | wc -l)" 23
        elif ! grep -qE "^$CRON_TEST1" <<< "$crontab"; then
            log "provided first crontab isn't part of container but should be" 24
        elif ! grep -qE "^$CRON_TEST2" <<< "$crontab"; then
            log "provided second crontab isn't part of container but should be" 25
        else
            log "successfully tested two cronjobs"
            log "$crontab"
        fi
    else
        log "container is unhealthy" 12
    fi

    # check supercron is running
    if docker exec -it "$CONTAINER" pidof supercronic > /dev/null; then
        log "supercronic started!"
    else
        log "supercronic NOT started" 13
    fi

    # fail for illegal cron job
    removeContainer "$CONTAINER"
    ./test/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" "-e" "CRON_illegal=* * * * echo \"hello illegal\""
    if ! awaitHealthCheck "$CONTAINER"; then
        log "successfully tested illegal cronjob"
    else
        log "container is healthy for illegal cronjob which should fail early" 14
    fi

    removeContainer "$CONTAINER"
)
