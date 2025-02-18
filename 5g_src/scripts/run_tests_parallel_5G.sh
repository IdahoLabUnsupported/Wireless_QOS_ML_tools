#!/bin/bash

while getopts p:s:e: flag
do
    case "${flag}" in
        s) START_CONFIG_ID=${OPTARG};;
        e) END_CONFIG_ID=${OPTARG};;
        p) MAX_PI_COUNT=${OPTARG};;
    esac
done

if [ ! "$MAX_PI_COUNT" ]||[ ! "$START_CONFIG_ID" ]||[ ! "$END_CONFIG_ID" ]; then
    echo "missing max pi count (-p) or start config id (-s) or end config id (-e)."
    exit 1
fi

#settings to make sure data transfer works
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE

for ((CONFIG_ID=$START_CONFIG_ID; CONFIG_ID<=$END_CONFIG_ID; CONFIG_ID++));
do
    echo "====================== Starting config $CONFIG_ID ======================="

    pi_config_success_count=0
    while [ $pi_config_success_count -ne $MAX_PI_COUNT ];
    do
        pi_config_success_count=0
        for ((i=0; i<$MAX_PI_COUNT; i++));
        do
            echo "pi$i"
            config_setup_script=". /home/ubuntu/scripts/config_ue.sh -c $CONFIG_ID"
            ping_script=". /home/ubuntu/scripts/ping_ue.sh -p $i"

            #"config setup" changes config file to the one we are testing
            ssh -l ubuntu 192.168.1.10$i "${config_setup_script}"

            #"ping script" makes sure pis connected to gNB
            ssh -l ubuntu 192.168.1.10$i "${ping_script}" &
            pids[${i}]=$!
        done

        for pid in "${pids[@]}"; do
            wait $pid
            exit_code=$?
            #make sure test worked
            if [ ${exit_code} -eq 0 ]; then
                pi_config_success_count=$((pi_config_success_count + 1))
            fi
        done
    done

    # loop through file direction (download/upload)
    DIRECTIONS="down up"
    #do tests
    for ((PI_COUNT=1; PI_COUNT<=$MAX_PI_COUNT; PI_COUNT++ ))
    do
        echo "--------- Starting tests for pi count $PI_COUNT ---------"
        TEST_ID=0

        for DIRECTION in ${DIRECTIONS};
        do  

            #loop through each file to test
            for TESTFILE in /home/ubuntu/ldrd/files/*;
            do
                success=0
                
                while [ $success -ne 1 ];
                do

                    failed_test=0
                    for ((i=0; i<$PI_COUNT; i++ ));
                    do
                        #do all the tests
                        FILE_NAME="$(basename $TESTFILE)"
                        HOSTNAME="192.168.1.10${i}"
                        PI_NAME="pi${i}"

                        /home/ubuntu/ldrd/scripts/run_test.sh -a $HOSTNAME -c $CONFIG_ID -d $DIRECTION -f $FILE_NAME -n $PI_NAME -s $PI_COUNT -t $TEST_ID &
                        pids[${i}]=$!
                    done

                    #parallelize the test
                    for pid in "${pids[@]}"; do
                        wait $pid
                        exit_code=$?
                        #make sure test worked
                        if [ ${exit_code} -ne 0 ]; 
                        then
                            failed_test=$((failed_test + 1))
                            echo "test $TEST_ID failed on $PI_NAME, config $CONFIG_ID, trying again"
                        fi
                    done

                    #if tests worked then continue to the next set of tests
                    if [ $failed_test -eq 0 ];
                    then
                        success=1
                    else
                        echo "test $TEST_ID failed on $PI_NAME, config $CONFIG_ID, trying again"
                    fi
                done
                echo "---------------- done with test $TEST_ID ----------------"
                TEST_ID=$((TEST_ID + 1))

            done
        done
    done
    echo "====================== Done with config $CONFIG_ID ======================"

done
