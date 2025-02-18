# Generate the summary csv file for all of the data in a given configuration.
# Expected arguments - the output path for the csv (including filename.csv) and the configuration ID

import os
import sys
import csv
import glob
import pandas as pd

testdata = pd.read_csv('/home/fs/ldrd/scripts/testdata.csv')

def process_csv(csv_path, config_details, test_id, device, num_concurrent):
    df = pd.read_csv(csv_path)
    df.sort_values('timestamp', inplace=True)
    df['latency'] = df['timestamp'].diff()
    latency_stats = df['latency'].describe()

    testdata_row = testdata[testdata['test_id'] == int(test_id)]

    summary_data = {
        'configuration_id': config_details['configuration_id'],
        
        'wpa_enabled': config_details['wpa_enabled'],
        'wpa2_enabled': config_details['wpa2_enabled'],
        'tkip_enabled': config_details['tkip_enabled'],
        'ccmp_enabled': config_details['ccmp_enabled'],

        'router_mode': config_details['router_mode'],
        'channel_width': config_details['channel_width'],
        'disassoc_low_ack': config_details['disassoc_low_ack'],
        'skip_inactivity_poll': config_details['skip_inactivity_poll'],
        'hidden_ssid': config_details['hidden_ssid'],
        'test_id': test_id,
        'file_size_bytes': testdata_row['bytes'].values[0],
        'file_type': testdata_row['filetype'].values[0],
        'file_direction': testdata_row['direction'].values[0],
        'device_id': device,
        'num_concurrent': num_concurrent,
        'start_time': df['timestamp'].min(),
        'end_time': df['timestamp'].max(),
        'total_size_bytes': df['length'].sum(),
        'packets_received': len(df),
        'unique_packets': df.groupby(['seq_num', 'ack', 'flags']).ngroups,
        'mean_latency': latency_stats['mean'],
        'std_latency': latency_stats['std'],
        'min_latency': latency_stats['min'],
        'max_latency': latency_stats['max'],
        'median_latency': df['latency'].median()
    }

    return summary_data


def main():
    outpath = sys.argv[1]
    configuration_id = sys.argv[2]
    data_path = sys.argv[3]

    if not outpath:
        sys.exit("Missing output csv file path.")

    if not configuration_id:
        sys.exit("Missing configuration id.")

    if not data_path:
        data_path = "/home/fs/ldrd/data"

    # Get rid of the trailing / if one was provided.
    if data_path[-1] == '/':
        data_path = data_path[:-1]

    print(f"Processing records for configuration {configuration_id}.")

    config_df = pd.read_csv('/home/fs/ldrd/scripts/configuration_descriptions_2.csv')
    config_details = config_df[config_df['configuration_id'] == int(configuration_id)].to_dict(orient='records')[0]

    dataset = []
    for test_path in glob.glob(f"{data_path}/{configuration_id}/*"):
        test_id = os.path.basename(test_path)

        for num_concurrent_path in glob.glob(f"{test_path}/*"):
            num_concurrent = os.path.basename(num_concurrent_path)

            for datafile in glob.glob(f"{num_concurrent_path}/*.csv"):
                device = os.path.basename(datafile).replace(".csv", "")

                dataset.append(process_csv(datafile, config_details, test_id, device, num_concurrent))

    out_df = pd.DataFrame.from_records(dataset)
    out_df.to_csv(outpath, index=False)

    print(f"Completed configuration {configuration_id}.")


if __name__ == "__main__":
    main()
