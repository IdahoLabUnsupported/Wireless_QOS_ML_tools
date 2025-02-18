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

for ((CONFIG_ID=$START_CONFIG_ID; CONFIG_ID<=$END_CONFIG_ID; CONFIG_ID++));
do
    echo "====================== Starting config $CONFIG_ID ======================="

    #start service in background
    count=0
    for ((i=0; i<=$MAX_PI_COUNT; i++));
    do
        #break program if we have too many tries
        if [ $count -ge 20 ]
        then 
            echo "Could not verify pi$i ue service status, please try again later"
            exit 1
        fi

        config_setup_script=". /home/ubuntu/scripts/config_ue.sh -c $CONFIG_ID"
        ssh -l ubuntu 192.168.1.10$i "${config_setup_script}"

        # ./config_ue.sh -c $CONFIG_ID
        status_code=$?

        if [ $status_code -ne 0 ]
        then
            i=$((i - 1))
            count=$((count + 1))
            continue
        fi

        ping_script=". /home/ubuntu/scripts/ping_ue.sh -p $i"
        ssh -l ubuntu 192.168.1.10$i "${ping_script}"
        # ./ping_ue.sh -p $i
        # echo "looping through pis"

    done

    # loop through file direction (upload/download)
    DIRECTIONS="down up"
    #do tests
    for ((PI_COUNT=1; PI_COUNT<=$MAX_PI_COUNT; PI_COUNT++))
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
                    for ((i=0; i<$PI_COUNT; i++));
                    do
                        #do all the tests
                        # echo "doing a test"
                        FILE_NAME="$(basename $TESTFILE)"
                        HOSTNAME="192.168.1.10${i}"
                        PI_NAME="pi${i}"

                        /home/ubuntu/ldrd/scripts/run_test.sh -a $HOSTNAME -c $CONFIG_ID -d $DIRECTION -f $FILE_NAME -n $PI_NAME -t $TEST_ID
                        #make sure test worked
                        test_status_code=$?
                        if [ $test_status_code -ne 0 ]
                        then
                            failed_test=$((failed_test + 1))
                            echo "test $TEST_ID failed on $PI_NAME, config $CONFIG_ID, trying again"

                        fi
                    done

                    if [ $failed_test -eq 0 ]
                    then
                        success=1
                    fi
                done
                echo "---------------- done with test $TEST_ID ----------------"
                TEST_ID+=1

            done
        done
    done
    echo "====================== Done with config $CONFIG_ID ======================"

done
