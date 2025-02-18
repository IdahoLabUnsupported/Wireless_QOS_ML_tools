for ((CONFIGURATION_ID=1; CONFIGURATION_ID<=40; CONFIGURATION_ID++))
do
    cp /home/ubuntu/ldrd/data/${CONFIGURATION_ID}/summary.csv /home/ubuntu/ldrd/summary_files/1ft/run1/configuration_${CONFIGURATION_ID}_summary.csv
done