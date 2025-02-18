#!/bin/bash

# start ue and send it to background
sudo /home/ubuntu/UERANSIM/build/nr-ue -c /home/ubuntu/UERANSIM/config/open5gs-ue-main.yaml >/home/ubuntu/ue_trail.txt 2>&1 &
UE_PID=$!

# send PID to a file so we can stop the ue
echo "$UE_PID" > /home/ubuntu/scripts/PID/pid.txt
