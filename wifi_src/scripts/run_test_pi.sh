# The test section that runs on a pi.

# FILE_DIRECTION is either 'up' or 'down'
while getopts d:f: flag
do
    case "${flag}" in
        d) FILE_DIRECTION=${OPTARG};;
        f) FILENAME=${OPTARG};;
    esac
done

if [ ! "$FILE_DIRECTION" ] || [ ! "$FILENAME" ]; then
    echo 'Missing file direction (-d) or filename (-f).' >&2
    exit 1
fi

# 0. Delete data files if they exist to make sure there isn't a conflict.
rm -rf /home/ubuntu/data/data.csv # csv generated from pcap
rm -rf /home/ubuntu/data/data.pcap # traffic data
rm -rf /home/ubuntu/temp/* # Downloaded file, if any

# 1. Start tcpdump on pi
if [ $FILE_DIRECTION = "down" ];
then
    tcpdump src 192.168.1.178 or dst 192.168.1.178 and port 80 -w /home/ubuntu/data/data.pcap >/dev/null 2>&1 &
else
    tcpdump src 192.168.1.178 or dst 192.168.1.178 and port 8000 -w /home/ubuntu/data/data.pcap >/dev/null 2>&1 &
fi

# Get PID for background process
PID_TCPDUMP=$!


# 2. Make request
startdl=$(date +%s)

if [ $FILE_DIRECTION = "down" ];
then
    curl -s http://192.168.1.178/$FILENAME > /home/ubuntu/temp/$FILENAME
else
    HOSTNAME=$(hostname)
    curl -s -X POST http://192.168.1.178:8000/upload -F 'files=@/home/ubuntu/files/'${HOSTNAME}_$FILENAME
fi
# Get the status of the curl request when it finishes
curl_return_code=$?
enddl=$(date +%s)

echo "Request time for $(hostname): $(($enddl-$startdl)) seconds"


# 3. stop tcpdump on pi
kill $PID_TCPDUMP

RETRIES=0
until [ -f /home/ubuntu/data/data.pcap ]
do
    sleep 2
    if [ $RETRIES -gt 30 ]; then
        echo 'Never found /home/ubuntu/data/data.pcap file.' >&2
        echo $(ip a | grep -oE "\b(192.168.1.10[0-9])") >&2
        exit 1
    fi

    RETRIES=$((RETRIES + 1))
done

# Remove the downloaded file to free up space
rm -rf /home/ubuntu/temp/$FILENAME

# Check if curl was successful - if not, remove the pcap now and return an error
if [ ${curl_return_code} -ne 0 ]; then
    rm -rf /home/ubuntu/data/data.pcap
    exit 1
fi

# 4. parse pcap file into csv
python3 /home/ubuntu/scripts/parse_pcap.py /home/ubuntu/data/data.pcap /home/ubuntu/data/data.csv

# 5. cleanup pcap file
rm -rf /home/ubuntu/data/data.pcap