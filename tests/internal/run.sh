#!/bin/bash

args=()
debug=""
tag=""
volume=""
remove="false"
docker_run_mode="-it"
quick=""
image="lgsm-test"
container="lgsm-test"
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "run.sh [option] tag [args]"
            echo ""
            echo "options:"
            echo "-d            set entrypoint to bash"
            echo "--debug"
            echo "--detach      run in background instead of foreground"
            echo "-v          x    use volume x"
            echo "--volume    x"
            echo "--quick       enforce quick monitoring"
            echo "-i          x   target image, default=lgsm-test"
            echo "--image     x"
            echo "-c          x   container name default=lgsm-test"
            echo "--container x"
            echo ""
            echo "tag:"
            echo "lgsm          run lgsm image"
            echo "specific      run last created specific image $IMAGE:$tag"
            echo ""
            echo "args:"
            echo "every other argument is added to docker run ... IMAGE [args] "
            exit 0;;
        -d|--debug)
            debug="--entrypoint bash";;
        --detach)
            docker_run_mode="-dt";;
        -v|--volume)
            volume="-v $1:/home/linuxgsm"
            shift;;
        --quick)
            quick="--health-interval=10s";;
        -i|--image)
            image="$key";;
        -c|--container)
            container="$1"
            shift;;
        lgsm|specific)
            tag="$key";;
        *)
            echo "$key is argument for docker container"
            args+=("$key");;
    esac
done


if [ -z "$tag" ]; then
    echo "please provide the tag to execute as first argument lgsm or specific"
    exit 1
fi


cmds=(docker run $docker_run_mode --rm --name "$container" $volume $debug $quick "$image:$tag")
for arg in "$@"; do
    if [ "$arg" != "$1" ]; then
        cmds+=("$arg")
    fi
done

echo "${cmds[@]}"
"${cmds[@]}"

