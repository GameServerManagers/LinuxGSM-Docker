#!/bin/bash

set -o nounset
set -o pipefail

version="$1"
rebuild="false"

(
    cd "$(dirname "$0")/.."

    source "test/internal/api_various.sh"
    source "test/internal/api_docker.sh"
    source "test/steam_test_credentials"
    image="$DEFAULT_DOCKER_REPOSITORY"

    mapfile -d $'\n' -t servers < <(getServerCodeList "$version")
    for server in "${servers[@]}"; do
        echo "starting $server"
        container="$server-generateExamples"
        docker stop "$container" > /dev/null 2>&1 || true
        docker rm "$container" > /dev/null 2>&1 || true

        # run it once
        run=(./test/internal/run.sh --container "$container" --image "$image" --tag "$server" --detach)
        # assuming already build before? Else takes way more time.
        if "$rebuild" && ! ./test/single.sh --build-only --version "$version" --image "$image" "$server"; then
          echo "build failed, skipping"
          continue
        fi
        echo "${run[@]}"
        if ! "${run[@]}" > /dev/null; then
            echo "run failed, skipping"
            continue
        fi

        seconds=0
        echo -n "[info][awaitContainerStarted] waiting for $seconds"
        while docker exec "$container" ls > /dev/null 2>&1 && ! docker exec "$container" ls "$server" > /dev/null 2>&1; do
          sleep 1s # just waiting until linuxgsm is installed
          seconds=$((seconds+1))
          echo -en "\r[info][awaitContainerStarted] waiting for $seconds"
        done
        echo -e "\r[info][awaitContainerStarted] waited for $seconds "
        if ! docker exec "$container" ls > /dev/null 2>&1; then
          echo "[error] $container crashed"
          cmd=(docker logs "$container")
          echo "${cmd[@]}"
          "${cmd[@]}"
        fi

        # get all ports
        details="$(docker exec -it "$container" details 2>&1)"

        docker stop "$container" > /dev/null 2>&1 || true
        docker rm "$container" > /dev/null 2>&1 || true

        steam_credentials_needed=""
        if grep -qEe "(^|\s)$server(\s|$)" <<< "${credentials_enabled[@]}"; then
          steam_credentials_needed="$(printf '\n      # please fill your credentials below\n      - "CONFIGFORCED_steamuser="\n      - "CONFIGFORCED_steampass="\n')"
        fi

        # write docker-compose.yml
        compose_file="
# usage:
#  docker-compose -f ./examples/$server.yml up -d
volumes:
  serverfiles:

name: lgsm

services:
  $server:
    image: \"$image:$server\"
    tty: true
    restart: unless-stopped
    environment:
      - \"CRON_update_daily=0 7 * * * update\"$steam_credentials_needed
    volumes:
      - serverfiles:/home/linuxgsm
      - /etc/localtime:/etc/localtime:ro"
        echo "$compose_file" > "examples/$server.yml"

        # extract port info
        mapfile -t ports < <(echo "$details" | grep -E '^[a-zA-Z0-9_-]+\s+[0-9]+\s+[a-z]+\s+\S+')
        if [ "${#ports[@]}" -gt 0 ]; then
            echo "    ports:" >> "examples/$server.yml"

            # we have ports but maybe they are duplicate
            # => we need to merge the desc
            already_added=""
            for port_i in "${ports[@]}"; do
                desc="$(echo "$port_i" | awk '{ print $1 }')"
                value="$(echo "$port_i" | awk '{ print $2 }')"
                protocol="$(echo "$port_i" | awk '{ print $3 }')"

                merged_desc="$desc"
                for port_j in "${ports[@]}"; do
                  desc_j="$(echo "$port_j" | awk '{ print $1 }')"
                  value_j="$(echo "$port_j" | awk '{ print $2 }')"
                  protocol_j="$(echo "$port_j" | awk '{ print $3 }')"

                  # port/proto is identical
                  if [ "$value:$protocol" = "$value_j:$protocol_j" ] && ! grep -q "$desc_j" <<< "$merged_desc"; then
                    merged_desc="$merged_desc / $desc_j"
                  fi
                done

                if ! grep -q " $value/$protocol " <<< "$already_added"; then
                  already_added="$already_added $value/$protocol "
                  echo "      # $merged_desc" >> "examples/$server.yml"
                  echo "      - \"$value:$value/$protocol\"" >> "examples/$server.yml"
                fi
            done
        else
            echo "# couldn't extract ports, can only provide example how to configure it" >> "examples/$server.yml"
            echo "#    ports:" >> "examples/$server.yml"
            echo "#      - \"27015:27015/udp\"" >> "examples/$server.yml"
            echo "#      - \"27015:27015/tcp\"" >> "examples/$server.yml"
            
        fi
    done
)
