#!/bin/bash

while getopts a:c:d:f:n:s:t: flag
do
    case "${flag}" in
        a) PI_ADDRESS=${OPTARG};;
        c) CONFIGURATION_ID=${OPTARG};;
        d) FILE_DIRECTION=${OPTARG};;
        f) FILENAME=${OPTARG};;
        n) PI_NAME=${OPTARG};;
        s) NUM_SIMUL=${OPTARG};;
        t) TEST_ID=${OPTARG};;
    esac
done

#alert user if we are missing an option
if [ ! "$PI_ADDRESS" ] || [ ! "$CONFIGURATION_ID" ] || [ ! "$FILE_DIRECTION" ] || [ ! "$FILENAME" ] || [ ! "$TEST_ID" ] || [ ! "$NUM_SIMUL" ] || [ ! "$PI_NAME" ]; then
    echo 'Missing pi address (-a), configuration_id (-c), file direction (-d), filename (-f), pi name (-n), number of pis (s), or test_id (-t).' >&2
    exit 1
fi

# 1. Create the directories if they don't exist
mkdir -p /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL

# 2. Start TCPDUMP on core
if [ $FILE_DIRECTION = "down" ]
then
    tcpdump -i ogstun -n port 80 -w /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.pcap >/dev/null 2>&1 &
else
    tcpdump -i ogstun -n port 8000 -w /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.pcap >/dev/null 2>&1 &
fi

# Get PID for background process
PID_TCPDUMP_5g=$!

# 3. Run script on pi
SCRIPT="/home/ubuntu/scripts/run_test_pi.sh -d $FILE_DIRECTION -f $FILENAME"
ssh -l ubuntu $PI_ADDRESS "${SCRIPT}"
run_test_pi=$?

# 4. Stop tcpdump on 5g nuc
kill $PID_TCPDUMP_5g

# Make sure the pcap file is ready
RETRIES=0
until [ -f /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.pcap ]
do
    sleep 2
    if [ $RETRIES -gt 30 ]; then
        echo 'Never found 5g pcap file.' >&2
        exit 1
    fi

    RETRIES=$((RETRIES + 1))
done

if [ $run_test_pi -ne 0 ]; then
    echo "a test failed on pi$PI_ADDRESS, exiting"
    exit 1
fi

# 5. copy down pi csv, delete csv from pi
scp -q ubuntu@$PI_ADDRESS:/home/ubuntu/data/data.csv /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.csv
scp_exit_code=$?

if [ $scp_exit_code -ne 0 ]; then
    echo "scp failed copying the download data.csv to /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.csv"
    rm -f /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.csv
    rm -f /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.pcap
    exit 1
fi

REMOVE_SCRIPT="rm -f /home/ubuntu/data/data.csv"
ssh -l ubuntu $PI_ADDRESS "${REMOVE_SCRIPT}"

# 6. Delete uploaded file
if [ $FILE_DIRECTION = "up" ]; then
    cleanup=("/home/ubuntu/fs/upload_validation.sh -p $PI_NAME -f $FILENAME")
    ssh -l ubuntu 192.168.1.90 "${cleanup}"
    cleanup_exit_code=$?

    if [ $cleanup_exit_code -ne 0 ]; then
        echo "upload file missing, starting test over"
        ue_restart=("/home/ubuntu/scripts/stop_ue.sh; /home/ubuntu/scripts/start_ue.sh")
        ssh -l ubuntu $PI_ADDRESS "${ue_restart}"

        rm -f /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.pcap
        exit 1
    fi
fi

# 7. Process 5g nuc pcap and remove
python3 /home/ubuntu/ldrd/scripts/parse_pcap.py /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.pcap /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.csv
rm -f /home/ubuntu/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.5g.pcap
