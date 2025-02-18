#!/bin/bash

if test -f /home/ubuntu/scripts/PID/pid.txt; then
    echo "stopping UE"
    
    #grab process for UE
    UE_PID=$(</home/ubuntu/scripts/PID/pid.txt)

    #Kill ue
    sudo kill -SIGINT $UE_PID

    # delete file
    rm /home/ubuntu/scripts/PID/pid.txt
    # wait for ue to stop
    tail --pid=$UE_PID -f /dev/null
fi