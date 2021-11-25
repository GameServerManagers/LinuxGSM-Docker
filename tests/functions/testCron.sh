#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERSION="$1"
GAMESERVER="$2"
VOLUME="$3"
CONTAINER="linuxgsm-$GAMESERVER-testCron"
# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/../internal/api_docker.sh"
# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/../internal/api_various.sh"

(
    cd "$(dirname "$0")/../.."
    DOCKERFILE_CRONLOCATION="$(grep -Po '(?<=SUPERCRONIC_CONFIG=")[^"]*' Dockerfile)"

    ./tests/internal/build.sh "$VERSION" --latest "$GAMESERVER"

    function handleInterrupt() {
        removeContainer "$CONTAINER"
        exit 1
    }
    trap handleInterrupt SIGTERM SIGINT ERR

    # initial run = no cron
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --volume "$VOLUME" --tag "$GAMESERVER"
    if awaitHealthCheck "$CONTAINER"; then
        if [ "0" != "$(docker exec -it "$CONTAINER" cat "$DOCKERFILE_CRONLOCATION" | wc -l)" ]; then
            echo "[testCron] successful no cron job found"
        else
            echo "[error][testCron] container shouldn't have a cronjob"
            exit 20
        fi 
    else
        echo "[error][testCron] container is unhealthy"
        exit 10
    fi

    # inject one cron
    CRON_TEST1="* * * * echo \"hello world1\""
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --volume "$VOLUME" --tag "$GAMESERVER" "-e" "CRON_test1=$CRON_TEST1"
    if awaitHealthCheck "$CONTAINER"; then
        crontab="$(docker exec -it "$CONTAINER" cat "$DOCKERFILE_CRONLOCATION")"
        if [ "2" != "$(echo "$crontab" | wc -l)" ]; then
            echo "[error][testCron] expected two cron lines, found $(echo "$crontab" | wc -l)"
            exit 21
        elif ! grep -qE "^$CRON_TEST1" <<< "$crontab"; then
            echo "[error][testCron] provided crontab isn't part of container but should be"
            exit 22 
        else
            echo "[testCron] successfully tested one cronjob"
        fi 
    else
        echo "[error][testCron] container is unhealthy"
        exit 10
    fi

    # inject multiple cron
    CRON_TEST2="* * * * echo \"hello world2\""
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --volume "$VOLUME" --tag "$GAMESERVER" "-e" "CRON_test1=$CRON_TEST1" "-e" "CRON_test2=$CRON_TEST2"
    if awaitHealthCheck "$CONTAINER"; then
        crontab="$(docker exec -it "$CONTAINER" cat "$DOCKERFILE_CRONLOCATION")"
        if [ "3" != "$(echo "$crontab" | wc -l)" ]; then
            echo "[error][testCron] expected 3 cron lines, found $(echo "$crontab" | wc -l)"
            exit 23
        elif ! grep -qE "^$CRON_TEST1" <<< "$crontab"; then
            echo "[error][testCron] provided first crontab isn't part of container but should be"
            exit 24
        elif ! grep -qE "^$CRON_TEST2" <<< "$crontab"; then
            echo "[error][testCron] provided second crontab isn't part of container but should be"
            exit 25
        else
            echo "[testCron] successfully tested two cronjobs"
            echo "crontab:"
            echo "$crontab"
        fi 
    else
        echo "[error][testCron] container is unhealthy"
        exit 10
    fi

    removeContainer "$CONTAINER"
)
