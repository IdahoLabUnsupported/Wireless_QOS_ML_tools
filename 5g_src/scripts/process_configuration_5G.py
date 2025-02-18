# Generate the summary csv file for all of the data in a given configuration.
# Expected arguments - the output path for the csv (including filename.csv) and the configuration ID

import os
import sys
import csv
import glob
import pandas as pd

test_data = pd.read_csv('/home/ubuntu/ldrd/scripts/testdata.csv')

def process_csv(csv_path, config_details, test_id, device, num_concurrent):
    df = pd.read_csv(csv_path)
    df.sort_values('timestamp', inplace=True)
    df['latency'] = df['timestamp'].diff()
    latency_stats = df['latency'].describe()
    test_data_row = test_data[test_data['test_id'] == int(test_id)]

    summary_data = {
        'configuration_id': config_details['configuration_id'],
        'integrity_algorithm': config_details['integrity_algorithm'],
        'encryption_algorithm': config_details['encryption_algorithm'],
        
        'test_id': test_id,
        'file_size_bytes': test_data_row['bytes'].values[0],
        'file_type': test_data_row['filetype'].values[0],
        'file_direction': test_data_row['direction'].values[0],
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

    if not outpath:
        sys.exit("Missing output csv file path.")

    if not configuration_id:
        sys.exit("Missing configuration id.")

    print(f"Processing records for configuration {configuration_id}.")

    config_df = pd.read_csv('/home/ubuntu/ldrd/scripts/config_desc5G.csv')
    config_details = config_df[config_df['configuration_id'] == int(configuration_id)].to_dict(orient='records')[0]

    dataset = []
    for test_path in glob.glob(f"/home/ubuntu/ldrd/data/{configuration_id}/*"):
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
