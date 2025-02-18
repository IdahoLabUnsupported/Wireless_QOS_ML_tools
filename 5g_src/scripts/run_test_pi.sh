#!/bin/bash

# The test section that runs on a pi.

# FILE_DIRECTION is either 'up' or 'down'
while getopts d:f: flag
do
    case "${flag}" in
        d) FILE_DIRECTION=${OPTARG};;
        f) FILENAME=${OPTARG};;
    esac
done

#alert user if we are missing an option
if [ ! "$FILE_DIRECTION" ] || [ ! "$FILENAME" ]; then
    echo 'Missing file direction (-d) or filename (-f).' >&2
    exit 1
fi

# 1. Start tcpdump on pi
if [ $FILE_DIRECTION = "down" ];
then
    tcpdump -i uesimtun0 src 192.168.1.90 or dst 192.168.1.90 and port 80 -w /home/ubuntu/data/data.pcap >/dev/null 2>&1 &
else
    tcpdump -i uesimtun0 src 192.168.1.90 or dst 192.168.1.90 and port 8000 -w /home/ubuntu/data/data.pcap >/dev/null 2>&1 &
fi

# Get PID for background process
PID_TCPDUMP=$!

# 2. Make curl request
startdl=$(date +%s)
if [ $FILE_DIRECTION = "down" ];
then
    curl --interface uesimtun0 -m 120 -s http://192.168.1.90/$FILENAME > /home/ubuntu/temp/$FILENAME

    #Check if curl downloaded file successfully
    if [ "test -f /home/ubuntu/temp/$FILENAME" ]; 
    then

        cmp /home/ubuntu/files/$FILENAME /home/ubuntu/temp/$FILENAME
        cmp_code=$?
        if [ $cmp_code -ne 0 ];
        then
            echo "file different"
            #restart the UE
            /home/ubuntu/scripts/stop_ue.sh

            /home/ubuntu/scripts/start_ue.sh

            kill $PID_TCPDUMP

            exit 1
        fi
    else
        stat_code=0
    fi    

else
    curl --interface uesimtun0 -s http://192.168.1.90:8000/upload -F 'files=@/home/ubuntu/files/up_files/'${HOSTNAME}_$FILENAME

fi

status_code=$?

enddl=$(date +%s)
if [ $status_code -ne 0 ];
then
    echo "curl exit code: $status_code"

    #restart the UE
    /home/ubuntu/scripts/stop_ue.sh

    /home/ubuntu/scripts/start_ue.sh

    exit 1

fi

# 3. stop tcpdump on pi
kill $PID_TCPDUMP

echo "Request time for $(hostname): $(($enddl-$startdl)) seconds"


# wait until we can see the pcap file
RETRIES=0
until [ -f /home/ubuntu/data/data.pcap ]
do
    # echo "starting until loop"
    sleep 2
    if [ $RETRIES -gt 5 ]; then
        echo 'Never found /home/ubuntu/data/data.pcap file.'
        echo $(ip a | grep -oE "\b(192.168.1.10[0-9])")

        #cleanup pcap file and downloaded file
        rm -f /home/ubuntu/data/data.pcap
        rm -f /home/ubuntu/temp/$FILENAME


        exit 1
    fi

    RETRIES=$((RETRIES + 1))
done

# 4. parse pcap file into csv
python3 /home/ubuntu/scripts/parse_pcap.py /home/ubuntu/data/data.pcap /home/ubuntu/data/data.csv
pcap_exit_code=$?
if [ $pcap_exit_code -ne 0 ];
then 
    echo "attempt to parse_pcap failed starting test over"
    #cleanup pcap file and downloaded file
    rm -f /home/ubuntu/data/data.pcap
    rm -f /home/ubuntu/temp/$FILENAME

    exit 1
fi

# 5. cleanup pcap file and downloaded file
rm -f /home/ubuntu/data/data.pcap
rm -f /home/ubuntu/temp/$FILENAME