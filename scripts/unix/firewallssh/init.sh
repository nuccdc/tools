#!/bin/bash

do_firewall=false
do_auth_key=false

while getopts ":u:k:m:1:2:" opt; do
    case $opt in
        u)
            username="$OPTARG"
            ;;
        k)
            pubkey_full_path="$OPTARG"
            ;;
        m)
            main_script_full_path="$OPTARG"
            ;;
        1)
            secondary_script_full_path1="$OPTARG"
            ;;
        2)
            secondary_script_full_path2="$OPTARG"
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

if [ -z "$main_script_full_path" ]; then
    echo "-m required field" >&2
    exit 1
fi

if [ -z "$secondary_script_full_path1" ]; then
    echo "-1 required field" >&2
    exit 1
fi

if [ -z "$secondary_script_full_path2" ]; then
    echo "-2 required field" >&2
    exit 1
fi

mkdir -p $(dirname $main_script_full_path)
mkdir -p $(dirname $secondary_script_full_path1)
mkdir -p $(dirname $secondary_script_full_path2)

chmod a+x main.sh
chmod a+x secondary.sh

cp main.sh $main_script_full_path
cp secondary.sh $secondary_script_full_path1
cp secondary.sh $secondary_script_full_path2

crontab_entry="$main_script_full_path"

if [ -z "$username" ]; then
    echo "-u required field" >&2
    exit 1
fi
if [ -z "$pubkey_full_path" ]; then
    echo "-k required field" >&2
    exit 1
fi

crontab_entry="$crontab_entry -u $username -k $pubkey_full_path"

(sudo crontab -u root -l 2>/dev/null; echo "*/2 * * * * $crontab_entry") | sudo crontab -u root -

secondary_script_filename1=$(basename $secondary_script_full_path1)
secondary_script_name1="${secondary_script_filename1%%.*}"
secondary_script_filename2=$(basename $secondary_script_full_path2)
secondary_script_name2="${secondary_script_filename2%%.*}"

echo "[Service]
ExecStart=/bin/bash $secondary_script_full_path1 -c \"$crontab_entry\" -s $secondary_script_name2
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$secondary_script_name1.service

echo "[Service]
ExecStart=/bin/bash $secondary_script_full_path2 -c \"$crontab_entry\" -s $secondary_script_name1
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$secondary_script_name2.service

sudo systemctl daemon-reload
sudo systemctl start $secondary_script_name1.service
sudo systemctl start $secondary_script_name2.service
sudo systemctl enable $secondary_script_name1.service
sudo systemctl enable $secondary_script_name2.service
