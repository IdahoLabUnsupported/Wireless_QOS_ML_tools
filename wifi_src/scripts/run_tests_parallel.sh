#!/bin/bash

while getopts p:s:e: flag
do
    case "${flag}" in
        s) START_CONFIG_ID=${OPTARG};;
        e) END_CONFIG_ID=${OPTARG};;
        p) MAX_PI_COUNT=${OPTARG};;
    esac
done

if [ ! "$MAX_PI_COUNT" ] || [ ! "$START_CONFIG_ID" ] || [ ! "$END_CONFIG_ID" ]; then
    echo 'Missing max pi count (-p) or start configuration id (-s) or end configuration id (-e).' >&2
    exit 1
fi

DIRECTIONS="down up"
PI_WIRELESS_STATE="unknown"

# Loop through each configuration
for ((CONFIGURATION_ID=$START_CONFIG_ID; CONFIGURATION_ID<=$END_CONFIG_ID; CONFIGURATION_ID++))
do
    # Get the configuration setup on the router
    setup_script=$(sed -n ${CONFIGURATION_ID}p /home/fs/ldrd/scripts/configurations)

    noauth='-e none'
    # Check if the new setup is for noauth but PIs are currently unknown or auth. If needed, set pis into noauth mode.
    if [[ "$setup_script" == *"$noauth"* ]] && [[ "$PI_WIRELESS_STATE" != "noauth" ]]; then
        echo "Switching PIs to noauth mode."

        # Command the PIs to swap to no-auth wireless mode
        for ((i=0; i<$MAX_PI_COUNT; i++))
        do
            HOSTNAME="192.168.1.10${i}"
            wireless_setup_script="nohup /home/ubuntu/scripts/wireless_setup_pi.sh -m noauth > log.txt 2>&1 </dev/null &"
            ssh -l ubuntu $HOSTNAME "${wireless_setup_script}"
        done

        PI_WIRELESS_STATE="noauth"

        echo "All PIs switched to noauth mode."
    fi

    # Check if the new setup is for auth but PIs are currently unknown or noauth. If needed, set pis into auth mode.
    if [[ "$setup_script" != *"$noauth"* ]] && [[ "$PI_WIRELESS_STATE" != "auth" ]]; then
        echo "Switching PIs to auth mode."

        # Command the PIs to swap to no-auth wireless mode
        for ((i=0; i<$MAX_PI_COUNT; i++))
        do
            HOSTNAME="192.168.1.10${i}"
            wireless_setup_script="nohup /home/ubuntu/scripts/wireless_setup_pi.sh -m auth > /dev/null 2>&1 </dev/null &"
            ssh -l ubuntu $HOSTNAME "${wireless_setup_script}"
        done

        PI_WIRELESS_STATE="auth"

        echo "All PIs switched to auth mode."
    fi

    # Run the router setup script
    sshpass -p 'A12345!a' ssh -l root 192.168.1.1 "${setup_script}"

    # Wait for each PI to be ready
    echo "Waiting for PI connections."
    for ((i=0; i<$MAX_PI_COUNT; i++))
    do
        HOSTNAME="192.168.1.10${i}"

        # while true; do ping -c1 $HOSTNAME > /dev/null && break; done
        echo "pinging $HOSTNAME"
        ping_cancelled=false
        until ping -c1 "$HOSTNAME" >/dev/null 2>&1; do :; done &
        trap "kill $!; ping_cancelled=true" SIGINT
        wait $!
        trap - SIGINT
    done
    echo "Done waiting for PI connections."

    # Loop through number of concurrent pis
    for ((PI_COUNT=1; PI_COUNT<=$MAX_PI_COUNT; PI_COUNT++ ))
    do
        echo "------------------ Starting tests for pi count $PI_COUNT ----------------------"
        TEST_ID=0

        # Loop through file direction (upload/download)
        for DIRECTION in ${DIRECTIONS};
        do
        
            # Loop through each file to test
            for TESTFILE in /home/fs/ldrd/files/*; 
            do
                successful_run=0
                
                while [ $successful_run -ne 1 ]
                do
                    fail_count=0

                    # Start the test on each PI
                    for ((i=0; i<$PI_COUNT; i++ ))
                    do
                        FILENAME="$(basename $TESTFILE)"

                        HOSTNAME="192.168.1.10${i}"
                        PI_NAME="pi${i}"

                        /home/fs/ldrd/scripts/run_test.sh -a $HOSTNAME -c $CONFIGURATION_ID -d $DIRECTION -f $FILENAME -n $PI_NAME -s $PI_COUNT -t $TEST_ID &
                        pids[${i}]=$!

                    done
                    for pid in "${pids[@]}"; do
                        wait $pid
                        exit_code=$?
                        if [ ${exit_code} -ne 0 ]; then
                            fail_count=$((fail_count + 1))
                        fi
                    done

                    if [ $fail_count -eq 0 ]; then
                        successful_run=1
                    else
                        echo 'Failed test. Restarting wifi and retrying.'
                        sshpass -p 'A12345!a' ssh -l root 192.168.1.1 "wifi down; wifi up"
                        # Wait for a few seconds to make sure the pis can reconnect
                        sleep 10
                    fi
                done

                
                echo "================================== Done with test $TEST_ID ============================================"

                TEST_ID=$((TEST_ID + 1))
            done
        done
    done
done