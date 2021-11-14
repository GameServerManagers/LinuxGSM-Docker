#!/bin/bash

function existsContainer() {
    [ -z "$(docker ps --all --filter name="$1" -q)" ]
}

function getContainerState() {
    docker ps --all --filter name="$1" --format "{{.Status}}"
}

function hasContainerHealthCheak() {
    [ "$(docker inspect -f '{{.State.Health}}' "$1")" != "<nil>" ]
}

function isContainerHealthStarting() {
    getContainerState "$container" | grep -qF '(health: starting)'
}

function isContainerHealthHealthy() {
    getContainerState "$container" | grep -qF '(healthy)'
}

function removeContainer() {
    docker stop "$1" > /dev/null 2>&1 || true
    docker rm "$1" > /dev/null 2>&1 || true
}

function awaitHealthCheck() {
    container="$1"
    
    if existsContainer "$container" || ! hasContainerHealthCheak "$container"; then
        return 1
    fi

    echo -n "[awaitHealthCheck] waiting for health check of \"$container\" "
    seconds=0
    while isContainerHealthStarting "$container"; do
        seconds=$((seconds+1))
        sleep 1s
        echo -en "\r[awaitHealthCheck] waiting for health check of \"$container\" currently ${seconds} seconds"
    done
    echo ""
    echo "[awaitHealthCheck] \"$container\" health check startup time $seconds"

    isContainerHealthHealthy "$container"
}