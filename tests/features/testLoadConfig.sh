#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/../internal/api_docker.sh"

#VERSION="$1"
GAMESERVER="$2"
VOLUME="$3"
CONTAINER="linuxgsm-$GAMESERVER-testLoadConfig"
configfile_common="/home/linuxgsm/lgsm/config-lgsm/$GAMESERVER/common.cfg"

(
    cd "$(dirname "$0")/../.."

    function log() {
        if [ -n "${2:-}" ]; then
            echo "[error][testLoadConfig] $1 exit code $2"
            removeContainer "$CONTAINER"
            echo "${3:-}"
            exit "$2"
        else
            echo "[info][testLoadConfig] $1"
        fi
    }
    
    inContainer=(docker exec -it "$CONTAINER")

    # test valid CONFIG_ -> common.cfg
    maxbackups="$RANDOM"
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" \
        -e CONFIG_maxbackups="$maxbackups"
    if awaitHealthCheck "$CONTAINER"; then
        log "container started with maxbackups injected"
        common_cfg="$( "${inContainer[@]}" cat "$configfile_common" || true )"
        if ! grep -qE "^maxbackups=\"$maxbackups\"" <<< "$common_cfg"; then
            log "environment variable for maxbackups not added to common.cfg" 21 "$common_cfg"
        else
            log "maxbackups successfully added!"
        fi
    else 
        log "container didn't start with steamcredentials" 20 "$(docker logs "$CONTAINER")"
    fi

    # test steam credentials with CONFIGFORCED_ -> common.cfg (two different usages)
    # using slightly different keys because illegal credentials will break the container
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" \
        -e CONFIGFORCED_steamuser_test="new Steam User" -e "CONFIGFORCED_steampass_test=new Steam Password"
    if awaitHealthCheck "$CONTAINER"; then
        log "container started with steam credentials injected"
        common_cfg="$( "${inContainer[@]}" cat "$configfile_common" || true )"
        if ! grep -qE '^steamuser_test="new Steam User"' <<< "$common_cfg"; then
            log "environment variable for steamuser not added to common.cfg" 21 "$common_cfg"
        elif ! grep -qE '^steampass_test="new Steam Password"' <<< "$common_cfg"; then
            log "environment variable for steampassword not added to common.cfg" 22 "$common_cfg"
        else
            log "steamuser and steampass successfully added!"
        fi
    else 
        log "container didn't start with steamcredentials" 20 "$(docker logs "$CONTAINER")"
    fi

    # test overwriting lgsm common.cfg on every start
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER"
    if awaitHealthCheck "$CONTAINER"; then
        log "container started, checking if common.cfg is overwritten"
        common_cfg="$("${inContainer[@]}" cat "$configfile_common" || true)"
        if grep -qE '^steamuser="newSteamUser"' <<< "$common_cfg"; then
            log "environment variable for steamuser still there, common.cfg not overwritten" 24 "$common_cfg"
        elif grep -qE '^steamuser="newSteamUser"' <<< "$common_cfg"; then
            log "environment variable for steampass still there, common.cfg not overwritten" 25 "$common_cfg"
        else
            log "common.cfg successfully overwritten on startup!"
        fi
    else 
        log "container didn't start, cant check if common.cfg is overwritten " 23 "$(docker logs "$CONTAINER" || true )"
    fi

    # test illegal CONFIG_ value which isn't part of _default.cfg -> expecting crash
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" \
        -e CONFIG_steamuser_illegal="newSteamUser"
    if ! awaitHealthCheck "$CONTAINER"; then
        log "container didn't start with illegal CONFIG value \"steamuser_illegal\""
    else 
        log "illegal CONFIG option didn't break the container" 26 "$(docker logs "$CONTAINER" || true)"
    fi

    # test valid GAME_ entry which isn't already part of the game cfg
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" \
        -e GAME_steamuser_illegal="newSteamUser"
    if awaitHealthCheck "$CONTAINER"; then
        log "container started with valid GAME_ value"
        lgsm_details="$(printf "%s\n" "$("${inContainer[@]}" lgsm-details 2>&1 | tr -d '\r' || true )")"
        configfile_game="$( grep -Eo 'Config file:.*' <<< "$lgsm_details" | grep -o '/.*' || true )"
        if [ -n "$configfile_game" ]; then
            log "found game configfile: \"$configfile_game\""
            configfile_game_content="$( "${inContainer[@]}" cat "$configfile_game" 2>&1 || true )"
            if grep -qE '^steamuser_illegal[^"]*"newSteamUser"' <<< "$configfile_game_content"; then
                log "successfully injected GAME_steamuser_illegal"
                # remove entries
                docker run -it --rm -v "$VOLUME:/home/linuxgsm" alpine sh -c "head -n -3 '$configfile_game' > /tmp/file.test 2>&1; cat /tmp/file.test > '$configfile_game'"
            else
                log "failed to inject GAME_steamuser_illegal" 29 "$configfile_game_content $(docker logs "$CONTAINER" || true )"
            fi
        else
            log "couldn't determine game config file" 28
        fi
    else 
        log "container didn't start with valid GAME_ env" 27 "$(docker logs "$CONTAINER" || true )"
    fi

    # test valid GAME_ entry with modified pattern which isn't already part of the game cfg
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" \
        -e GAME_steamuser_test="newSteamUser" -e LGSM_CONFIG_PATTERN_GAME="// test-comment !§$%\\&/()%s{\\[]}\\\\%s@€"
    if awaitHealthCheck "$CONTAINER"; then
        log "container started with valid GAME_ value and custom pattern"
        lgsm_details="$(printf "%s\n" "$("${inContainer[@]}" lgsm-details 2>&1 | tr -d '\r' || true )")"
        configfile_game="$( grep -Eo 'Config file:.*' <<< "$lgsm_details" | grep -o '/.*' || true )"
        if [ -n "$configfile_game" ]; then
            log "found game configfile: \"$configfile_game\""
            configfile_game_content="$( "${inContainer[@]}" cat "$configfile_game" 2>&1 || true )"
            if [ -z "$configfile_game_content" ]; then
                log "extracted configfile is empty, therefore failed to inject GAME_ variable" 33
            elif grep -qE '^!§$%&/()steamuser_illegal{\[]}\newSteamUser' <<< "$configfile_game_content"; then
                log "failed to inject GAME_steamuser_illegal" 32 "$configfile_game_content $(docker logs "$CONTAINER" || true )"
            else
                log "successfully injected GAME_steamuser_illegal with custom pattern"
                # remove entries
                docker run -it --rm -v "$VOLUME:/home/linuxgsm" alpine sh -c "head -n -2 '$configfile_game' > /tmp/file.test 2>&1; cat /tmp/file.test > '$configfile_game'"
            fi
        else
            log "couldn't determine game config file" 31
        fi
    else 
        log "container didn't start with valid GAME_ env, you probably need to fix this manually" 30 "$(docker logs "$CONTAINER" || true )"
    fi

    # test valid GAME_ entry which is already part of the game cfg
    hostname="$RANDOM"
    removeContainer "$CONTAINER"
    ./tests/internal/run.sh --container "$CONTAINER" --detach --quick --volume "$VOLUME" --tag "$GAMESERVER" \
        -e GAME_hostname="$hostname"
    if awaitHealthCheck "$CONTAINER"; then
        log "container started with valid GAME_ value which is/was already part of game config"
        lgsm_details="$(printf "%s\n" "$("${inContainer[@]}" lgsm-details 2>&1 | tr -d '\r' || true )")"
        configfile_game="$( grep -Eo 'Config file:.*' <<< "$lgsm_details" | grep -o '/.*' || true )"
        if [ -n "$configfile_game" ]; then
            log "found game configfile: \"$configfile_game\""
            configfile_game_content="$("${inContainer[@]}" cat "$configfile_game")"
            # only valid for gmodserver and similiar
            if ! grep -qE "^hostname\s*\"$hostname\"" <<< "$configfile_game_content"; then
                log "failed to inject existing GAME_ config" 35 "$configfile_game_content $(docker logs "$CONTAINER" || true )"
            elif [ "1" -ne "$(grep -oE '^hostname' <<< "$configfile_game_content" | wc -l)" ]; then
                log "injected GAME_config is injected but not replaced" 36 "$configfile_game_content $(docker logs "$CONTAINER" || true )"
            else
                log "successfully replaced existing GAME_config"
            fi
        else
            log "couldn't determine game config file" 37
        fi
    else 
        log "container didn't start with valid GAME_ env" 33 "$(docker logs "$CONTAINER" || true )"
    fi

    removeContainer "$CONTAINER"
)
