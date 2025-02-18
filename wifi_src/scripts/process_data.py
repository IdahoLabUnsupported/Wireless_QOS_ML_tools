import sys
import csv
import glob
import pandas as pd


outpath = sys.argv[1]
direction = sys.argv[2]
configuration_id = sys.argv[3]
test_id = sys.argv[4]
pi_id = sys.argv[5]

if not outpath:
    sys.exit("Missing csv file path.")

if not direction:
    sys.exit("Missing test direction (up/down).")

if not configuration_id:
    sys.exit("Missing configuration id.")

if not test_id:
    sys.exit("Missing test id.")

if not pi_id:
    sys.exit("Missing pi id.")



pi_df = pd.read_csv(f'/home/fs/ldrd/data/csv/{configuration_id}/{test_id}/pi{pi_id}.csv')
pi_df.sort_values('timestamp', inplace=True)
pi_df['latency'] = pi_df['timestamp'].diff()
pi_latency_stats = pi_df['latency'].describe()

summary_data = {
    'configuration_id': configuration_id,
    'test_id': test_id,
    'device_id': pi_id,
    'start_time': pi_df['timestamp'].min(),
    'end_time': pi_df['timestamp'].max(),
    'total_size_bytes': pi_df['length'].sum(),
    'packets_received': len(pi_df),
    'unique_packets': pi_df.groupby(['seq_num', 'ack', 'flags']).ngroups,
    'mean_latency': pi_latency_stats['mean'],
    'std_latency': pi_latency_stats['std'],
    'min_latency': pi_latency_stats['min'],
    'max_latency': pi_latency_stats['max'],
    'median_latency': pi_df['latency'].median()
}

print(summary_data)