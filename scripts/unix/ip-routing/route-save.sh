#!/bin/bash

usage() {
    echo "Usage: $0 [directory]"
    echo "Saves the current IP route configuration."
    echo "If no directory is specified, saves to /tmp/ip-routes/ with a timestamp."
    echo
    echo "Arguments:"
    echo "  directory    Optional. Specify a custom directory to save the routing table."
    echo
    echo "Options:"
    echo "  --help, -h   Display this help message and exit."
}

if [[ "$1" == "--help" ]] || [[ "$1" == "help" ]] || [[ "$1" == "-h" ]]; then
    usage
    exit 0
fi

if [ "$#" -eq 1 ]; then
    FILENAME=$1
    ip route show > $FILENAME
    echo "Routing table saved to $FILENAME"

else
    SAVE_DIR="/tmp/ip-routes"
    mkdir -p $SAVE_DIR
    timestamp=$(date +"%Y%m%d-%H%M%S")
    FILENAME="$SAVE_DIR/ip-routes-$timestamp.txt"
    ip route show > $FILENAME
    echo "Routing table saved to $FILENAME"
fi
