#!/bin/bash
while getopts s:e:i:o: flag
do
    case "${flag}" in
        s) START_CONFIG_ID=${OPTARG};;
        e) END_CONFIG_ID=${OPTARG};;
        i) INPUT_DIR=${OPTARG};;
        o) OUTPUT_DIR=${OPTARG};;
    esac
done

if [ ! "$START_CONFIG_ID" ] || [ ! "$END_CONFIG_ID" ] || [ ! "$INPUT_DIR" ] || [ ! "$OUTPUT_DIR" ]; then
    echo 'Missing start configuration id (-s) or end configuration id (-e) or input/data directory (-i) or output directory (-o).' >&2
    exit 1
fi

for ((CONFIGURATION_ID=$START_CONFIG_ID; CONFIGURATION_ID<=$END_CONFIG_ID; CONFIGURATION_ID++))
do
    python3 /home/ubuntu/ldrd/scripts/process_configuration_5G.py ${OUTPUT_DIR}/configuration_${CONFIGURATION_ID}_summary.csv ${CONFIGURATION_ID} ${INPUT_DIR}
done