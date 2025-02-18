#!/bin/bash

# Copy scripts out to PIs

HOSTS="192.168.1.100 192.168.1.101 192.168.1.102 192.168.1.103 192.168.1.104 192.168.1.105 192.168.1.106"

for HOSTNAME in ${HOSTS}; do
    # scp /home/ubuntu/ldrd/scripts/run_test_pi.sh ubuntu@$HOSTNAME:/home/ubuntu/scripts/run_test_pi.sh
    # scp -r /home/ubuntu/ldrd/files/* ubuntu@$HOSTNAME:/home/ubuntu/files/
    
    # scp /home/ubuntu/ldrd/scripts/parse_pcap.py ubuntu@$HOSTNAME:/home/ubuntu/scripts/parse_pcap.py

    # scp /home/ubuntu/ldrd/scripts/ping_ue.sh ubuntu@$HOSTNAME:/home/ubuntu/scripts/ping_ue.sh

    # scp /home/ubuntu/ldrd/scripts/config_ue.sh ubuntu@$HOSTNAME:/home/ubuntu/scripts/config_ue.sh

    # scp /home/ubuntu/ldrd/scripts/stop_ue.sh ubuntu@$HOSTNAME:/home/ubuntu/scripts/stop_ue.sh

    # scp /home/ubuntu/ldrd/scripts/start_ue.sh ubuntu@$HOSTNAME:/home/ubuntu/scripts/start_ue.sh

    # scp /home/ubuntu/ldrd/scripts/script_config/* ubuntu@$HOSTNAME:/home/ubuntu/scripts

    # SCRIPT="chmod +x /home/ubuntu/scripts/run_test_pi.sh; chmod +x /home/ubuntu/scripts/parse_pcap.py; chmod +x /home/ubuntu/scripts/ping_ue.sh; chmod +x /home/ubuntu/scripts/config_ue.sh; chmod +x /etc/systemd/system/sys_ue.service;"

    # sudo ssh -l ubuntu $HOSTNAME "${SCRIPT}"
    # sudo ssh -l ubuntu $HOSTNAME chmod +x /home/ubuntu/scripts/stop_ue.sh
    # sudo ssh -l ubuntu $HOSTNAME chmod +x /home/ubuntu/scripts/start_ue.sh
done

# chmod +x /etc/systemd/system/sys_ue.service