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

if [ ! "$PI_ADDRESS" ] || [ ! "$CONFIGURATION_ID" ] || [ ! "$FILE_DIRECTION" ] || [ ! "$FILENAME" ] || [ ! "$TEST_ID" ] || [ ! "$NUM_SIMUL" ] || [ ! "$PI_NAME" ]; then
    echo 'Missing pi address (-a), configuration_id (-c), file direction (-d), filename (-f), pi name (-n), number of pis (s), or test_id (-t).' >&2
    exit 1
fi

# 1. Create the directories if they don't exist
mkdir -p /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL

# 2. Start TCPDUMP on fs
if [ $FILE_DIRECTION = "down" ];
then
    tcpdump -i enx9cebe8cdc376 src $PI_ADDRESS or dst $PI_ADDRESS and port 80 -w /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.fs.pcap >/dev/null 2>&1 &
else
    tcpdump -i enx9cebe8cdc376 src $PI_ADDRESS or dst $PI_ADDRESS and port 8000 -w /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.fs.pcap >/dev/null 2>&1 &
fi


# Get PID for background process
PID_TCPDUMP_FS=$!

# 3. Run script on pi

SCRIPT="/home/ubuntu/scripts/run_test_pi.sh -d $FILE_DIRECTION -f $FILENAME"
ssh -l ubuntu $PI_ADDRESS "${SCRIPT}"
run_exit_code=$?

# 4. Stop tcpdump on fs

kill $PID_TCPDUMP_FS

# Make sure the pcap file is ready
RETRIES=0
until [ -f /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.fs.pcap ]
do
    sleep 2
    if [ $RETRIES -gt 30 ]; then
        echo 'Never found fs pcap file.' >&2
        exit 1
    fi

    RETRIES=$((RETRIES + 1))
done

# 5. Check that run_test_pi succeeded - if not, clean up and exit
if [ $run_exit_code -ne 0 ]; then
    rm -rf /home/fs/ldrd/upload/${PI_NAME}_${FILENAME}
    rm -rf /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.fs.pcap

    exit 1
fi

# 5. copy down pi csv, delete csv from pi

echo "PI_ADDRESS: $PI_ADDRESS, CONFIGURATION_ID: $CONFIGURATION_ID, FILE_DIRECTION: $FILE_DIRECTION, FILENAME: $FILENAME, PI_NAME: $PI_NAME, NUM_SIMUL: $NUM_SIMUL, TEST_ID: $TEST_ID" > /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/details.txt

scp -q ubuntu@$PI_ADDRESS:/home/ubuntu/data/data.csv /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.csv
scp_exit_code=$?

# Check that scp was successful
if [ $scp_exit_code -ne 0 ]; then
    echo "SCP failed to copy down file to location /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.csv"
    rm -rf /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.csv # Delete any partial file that may have ended up in the data
    exit 1
fi

# 6. Delete uploaded file
rm -rf /home/fs/ldrd/upload/${PI_NAME}_${FILENAME}

# 7. Process fs pcap and remove
python3 /home/fs/ldrd/scripts/parse_pcap.py /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.fs.pcap /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.fs.csv
rm -rf /home/fs/ldrd/data/$CONFIGURATION_ID/$TEST_ID/$NUM_SIMUL/$PI_NAME.fs.pcap
