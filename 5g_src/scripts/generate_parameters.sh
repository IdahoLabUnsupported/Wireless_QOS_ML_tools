#!/bin/bash
while getopts c:p: flag
do
    case "${flag}" in
        c) CONFIGURATION_ID=${OPTARG};;
        p) PI_COUNT=${OPTARG};;
    esac
done

if [ ! "$CONFIGURATION_ID" ] || [ ! "$PI_COUNT" ]; then
    echo 'Missing configuration id (-c) or pi count (-p).' >&2
    exit 1
fi


TEST_ID=0
DIRECTIONS="down up"

for DIRECTION in ${DIRECTIONS};
do
    for TESTFILE in /home/ubuntu/ldrd/files/*; 
    do
        for ((i=0; i<$PI_COUNT; i++ ))
        do
            FILENAME="$(basename $TESTFILE)"

            HOSTNAME="192.168.1.10${i}"
            PI_NAME="pi${i}"

            echo $HOSTNAME
            echo $CONFIGURATION_ID
            echo $DIRECTION
            echo $FILENAME
            echo $PI_NAME
            echo $PI_COUNT
            echo $TEST_ID
        done
        TEST_ID=$((TEST_ID + 1))
    done
done