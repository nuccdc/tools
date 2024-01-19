#!/bin/bash

while getopts ":c:s:" opt; do
    case $opt in
        c)
            cron_line="$OPTARG"
            ;;
        s)
            service="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [ -z "$cron_line" ]; then
    echo "-c required field" >&2
    exit 1
fi

if [ -z "$service" ]; then
    echo "-s required field" >&2
    exit 1
fi

while true; do
    cron_contents="$(sudo crontab -l)"
    if [[ "$cron_contents" != *"$cron_line"* ]]; then
        (sudo crontab -u root -l 2>/dev/null; echo "*/2 * * * * $cron_line") | sudo crontab -u root -
    fi

    if [[ "$(ps -ef)" != *"$service.service"* ]]; then
        sudo systemctl start $service.service
        sudo systemctl enable $service.service
    fi
    sleep 15
done
