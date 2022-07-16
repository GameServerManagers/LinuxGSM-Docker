#!/bin/bash

# shellcheck source=test/internal/api_various.sh
source "$(dirname "$0")/api_various.sh"

TAG=""
SUFFIX=""
docker_run_mode="-it"
IMAGE="$DEFAULT_DOCKER_REPOSITORY"
container="lgsm-test"

run_image=(docker run)
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][run] run.sh [option] [args]"
            echo "[help][run] "
            echo "[help][run] options:"
            echo "[help][run] -c  --container x  container name default=lgsm-test"
            echo "[help][run] -d  --debug        set entrypoint to bash"
            echo "[help][run]     --detach       run in background instead of foreground"
            echo "[help][run] -i  --image     x  target image, default=lgsm-test"
            echo "[help][run]     --suffix       add to tag provided suffix"
            echo "[help][run]     --tag       x  target tag"
            echo "[help][run]     --quick        enforce quick monitoring"
            echo "[help][run] -v  --volume    x  use volume x"
            echo "[help][run] "
            echo "[help][run] args:"
            echo "[help][run] x                  every other argument is added to docker run ... [args] IMAGE"
            exit 0;;
        -c|--container)
            container="$1"
            shift;;
        -d|--debug)
            run_image+=(--entrypoint "bash");;
        --detach)
            docker_run_mode="-dt";;
        -i|--image)
            IMAGE="$1"
            shift;;
        --suffix)
			if [ -n "$1" ]; then
            	SUFFIX="-$1"
			else
				echo "[warning][run] skipping suffix because its empty"
            fi
			shift;;
        -t|--tag)
            TAG="$1"
            shift;;
        --quick)
            run_image+=("--health-interval=10s" "--health-start-period=60s");;
        -v|--volume)
            run_image+=(-v "$1:/home/linuxgsm")
            shift;;
        *)
            if [ -n "$key" ]; then
                echo "[info][run] additional argument to docker: $key" | sed -E 's/(steamuser|steampass)=\S+/\1="xxx"/g'
                run_image+=("$key")
            fi
            ;;
    esac
done
run_image+=("$docker_run_mode" --name "$container" "$IMAGE:$TAG$SUFFIX")

echo "${run_image[@]}" | sed -E 's/(steamuser|steampass)=\S+/\1="xxx"/g'
"${run_image[@]}"

