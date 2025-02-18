#!/bin/bash

# Copy scripts out to PIs

HOSTS="192.168.1.100 192.168.1.101 192.168.1.102 192.168.1.103 192.168.1.104 192.168.1.105 192.168.1.106 192.168.1.107"

for HOSTNAME in ${HOSTS}; do
    rm -rf /home/ubuntu/testlogs
    rm -rf /home/ubuntu/data/*
    rm -rf /home/ubuntu/temp/*

    scp /home/fs/ldrd/scripts/run_test_pi.sh ubuntu@$HOSTNAME:/home/ubuntu/scripts
    scp -r /home/fs/ldrd/files ubuntu@$HOSTNAME:/home/ubuntu
    
    scp /home/fs/ldrd/scripts/parse_pcap.py ubuntu@$HOSTNAME:/home/ubuntu/scripts
    scp /home/fs/ldrd/scripts/wireless_setup_pi.sh ubuntu@$HOSTNAME:/home/ubuntu/scripts

    SCRIPT="chmod +x /home/ubuntu/scripts/run_test_pi.sh; chmod +x /home/ubuntu/scripts/parse_pcap.py"
    ssh -l ubuntu $HOSTNAME "${SCRIPT}"
done
    