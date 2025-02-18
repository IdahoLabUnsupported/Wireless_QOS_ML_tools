#!/bin/bash

while getopts p:f: flag
do
    case "${flag}" in
        p) PI_NAME=${OPTARG};;
        f) FILENAME=${OPTARG};;
    esac
done

if [ ! "test -f /home/ubuntu/fs/upload/${PI_NAME}_${FILENAME}" ];
then
    exit 1
fi

rm -f /home/ubuntu/fs/upload/${PI_NAME}_${FILENAME}