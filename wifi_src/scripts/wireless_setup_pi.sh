#! /bin/bash

while getopts m: flag
do
    case "${flag}" in
        m) MODE=${OPTARG};;
    esac
done

if [ ! "$MODE" ]; then
    echo 'Missing parameter mode (-m).' >&2
    exit 1
fi

if [ "$MODE" == "noauth" ]; then
    sudo cp /home/ubuntu/wireless_files/noauth.50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
else
    sudo cp /home/ubuntu/wireless_files/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
fi

sudo netplan generate
sudo netplan apply