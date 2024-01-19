#!/bin/bash
ROUTE_SAVE_SCRIPT="./route-save.sh"

last_timestamp=""

ip monitor route | while read -r line; do
    timestamp=$(date +"%Y%m%d-%H%M%S")
    if [[ "$timestamp" != "$last_timestamp" ]]; then
      SAVE_DIR="/tmp/ip-routes"
      FILENAME="$SAVE_DIR/ip-routes-$timestamp.txt"
      mkdir -p $SAVE_DIR
      echo "Route change detected at $timestamp. Saving saved route at $FILENAME"
      last_timestamp=$timestamp
      ip route show > $FILENAME
    fi
done
