#!/bin/bash

# quit if not root
if [ $UID -ne 0 ]; then
  echo "You must be root to run this script."
  exit 2
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file-path>"
    exit 1
fi

FILE_PATH="$1"

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: no file at $FILE_PATH"
    exit 1
fi

# delete the current routes
ip route flush table main

default_route=""

# read each line from the file and apply the route
while IFS= read -r line
do
    # extract interface name (it's always after dev in ip route output)
    iface=$(echo $line | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}')

    # if the interface doesn't exist, we just skip
    if [ -n "$iface" ] && ! ip link show "$iface" > /dev/null 2>&1; then
        echo "Skipping route as interface $iface does not exist: $line" 
        continue
    fi

    if [[ $line == default* ]]; then
        default_route=$line
    else
        # removing linkdown
        modified_line=$(echo "$line" | sed 's/linkdown//')
        ip route add $modified_line
    fi
done < "$FILE_PATH"

# add the default route last
if [ ! -z "$default_route" ]; then
    ip route add $default_route 
fi

echo "IP route configuration updated."
