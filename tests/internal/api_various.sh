#!/bin/bash

function isEmpty() {
    [ -z "$1" ]
}

function contains() {
    echo "$1" | grep -qF "$2" 
}
