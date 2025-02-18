#!/bin/bash

while getopts p: flag
do
    case "${flag}" in
        p) i=${OPTARG};;
    esac
done

if [ ! "$i" ]; then
    echo "missing pi count (-p)."
    exit 1
fi
count=0
#test connection

UE_NAME="192.168.1.10${i}"

echo "pinging from $UE_NAME"
ping_cancelled=false
until ping -I uesimtun0 -c1 192.168.1.90 >/dev/null 2>&1; 
do

    #break program if we have too many tries
    if [ $count -ge 10 ]
    then 
        echo "Could not ping pi $i"
        exit 1
    fi

    count=$((count + 1))
    sleep .5
    echo "slept and now I am trying again"
done

