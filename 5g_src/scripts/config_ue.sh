#!/bin/bash

while getopts c: flag
do
    case "${flag}" in
        c) CONFIG_ID=${OPTARG};;
    esac
done

#alert user if we are missing an option
if [ ! "$CONFIG_ID" ]; then
    echo "missing config id (-c)."
    exit 1
fi

# "stops ue"
/home/ubuntu/scripts/stop_ue.sh

# edit/select config for each pi
cp /home/ubuntu/scripts/open5gs-ue$CONFIG_ID.yaml /home/ubuntu/UERANSIM/config/open5gs-ue-main.yaml

# "starts ue"
/home/ubuntu/scripts/start_ue.sh

reg_code=1
count=0

while [ $reg_code -ne 0 ];
do
    sleep 1
    ue_name="$(UERANSIM/build/nr-cli --dump)"
    echo "waiting for ue to start up: $ue_name"
    UERANSIM/build/nr-cli $ue_name -e status | grep RM-REGISTERED
    reg_code=$?
    echo "reg_code $reg_code"
    
    count=$((count + 1))
    if [ $count -ge 20 ];
    then 
        echo "Could not start pi$i"
        continue
    fi
done