#!/bin/bash
while getopts c: flag
do
    case "${flag}" in
        c) CONFIGURATION_ID=${OPTARG};;
    esac
done

if [ ! "$CONFIGURATION_ID" ]; then
    echo 'Missing configuration id (-c).' >&2
    exit 1
fi


TEST_ID=0
DIRECTIONS="down up"

for DIRECTION in ${DIRECTIONS};
do
    for TESTFILE in /home/ubuntu/ldrd/files/*; 
    do
        FILENAME="$(basename $TESTFILE)"
        /home/ubuntu/ldrd/scripts/run_test.sh -a 192.168.1.100 -c $CONFIGURATION_ID -d $DIRECTION -f $FILENAME -n pi0 -s 1 -t $TEST_ID
        TEST_ID=$((TEST_ID + 1))
    done
done