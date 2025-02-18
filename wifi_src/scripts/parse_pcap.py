import sys
import dpkt
import csv

inpath = sys.argv[1]
outpath = sys.argv[2]

if not inpath:
    sys.exit("Missing pcap file path.")

if not outpath:
    sys.exit("Missing output file path.")

def process_pcap(fpath):
    temp_dataset = []

    with open(fpath, 'rb') as f:
        pcap = dpkt.pcap.Reader(f)
        for ts, buf in pcap:

            try:
                eth = dpkt.ethernet.Ethernet(buf)
                ip = eth.data
                tcp = ip.data

                temp = {
                    'timestamp': ts,
                    'length': ip.len,
                    'src_ip': '.'.join(str(c) for c in ip.src),
                    'dst_ip': '.'.join(str(c) for c in ip.dst),
                    'src_port': tcp.sport,
                    'dst_port': tcp.dport,
                    'seq_num': tcp.seq,
                    'ack': tcp.ack,
                    'flags': tcp.flags
                }
                temp_dataset.append(temp)
            except:
                continue
    
    return temp_dataset

dataset = process_pcap(inpath)

with open(outpath, 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['timestamp', 'length', 'src_ip', 'dst_ip', 'src_port', 'dst_port', 'seq_num', 'ack', 'flags'])

    for d in dataset:
        writer.writerow(d.values())