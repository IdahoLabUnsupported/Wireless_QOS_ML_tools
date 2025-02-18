#!/bin/bash

SCRIPT="/home/ubuntu/scripts/stop_ue.sh"

HOSTS="192.168.1.100 192.168.1.101 192.168.1.102 192.168.1.103 192.168.1.104 192.168.1.105 192.168.1.106"

for HOSTNAME in ${HOSTS}; do
    ssh -l ubuntu $HOSTNAME "${SCRIPT}"
done
