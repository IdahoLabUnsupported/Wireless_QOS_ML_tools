for ((CONFIGURATION_ID=1; CONFIGURATION_ID<=40; CONFIGURATION_ID++))
do
    cp /home/fs/ldrd/data/${CONFIGURATION_ID}/summary.csv /media/fs/qos_ldrd_data/5ft/run1/summary_files/configuration_${CONFIGURATION_ID}_summary.csv
done