#!/bin/bash

export PATH=/bin:/usr/bin:/usr/sbin

do_firewall=false
do_auth_key=false

while getopts ":u:k:" opt; do
    case $opt in
        u)
            username="$OPTARG"
            ;;
        k)
            pubkey_file="$OPTARG"
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

if [ -z "$username" ]; then
    echo "-u required field" >&2
    exit 1
fi
if [ -z "$pubkey_file" ]; then
    echo "-k required field" >&2
    exit 1
fi

ufw allow ssh

mkdir -p /home/$username/.ssh/
chmod 700 /home/$username/.ssh

if [[ "$(cat /home/$username/.ssh/authorized_keys)" != *"$(cat $pubkey_file)"* ]]; then
    cat $pubkey_file >> /home/$username/.ssh/authorized_keys
fi

chmod 600 /home/$username/.ssh/authorized_keys

if [[ "$(cat /etc/os-release)" == *"openSUSE"* ]]; then
    chown $username:users /home/$username/.ssh
    chown $username:users /home/$username/.ssh/authorized_keys
else
    chown $username:$username /home/$username/.ssh
    chown $username:$username /home/$username/.ssh/authorized_keys
fi

if [[ "$(sudo systemctl status ssh)" != *"Active: active"* ]]; then
    sudo systemctl start ssh
    if [ "$(echo $?)" == "0" ]; then
        sudo systemctl enable ssh
    else
        sudo systemctl start sshd
        sudo systemctl enable sshd
    fi
fi
