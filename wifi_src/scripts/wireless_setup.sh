# https://openwrt.org/docs/guide-user/network/wifi/guestwifi/configuration_command_line_interface

while getopts e:h:s:d: flag
do
    case "${flag}" in
        d) DISASSOC_LOW_ACK=${OPTARG};;
        e) ENCRYPTION_TYPE=${OPTARG};;
        h) HTMODE=${OPTARG};;
        s) SKIP_INACTIVITY_POLL=${OPTARG};;
    esac
done                                                
                                                                     
if [ ! "$ENCRYPTION_TYPE" ] || [ ! "$HTMODE" ]; then                 
    echo 'Missing encryption type (-e) flag or htmode (-h) flag.' >&2
    exit 1
fi                                       
                                         
if [ ! "$DISASSOC_LOW_ACK" ]; then       
    DISASSOC_LOW_ACK=1                   
fi
                                         
if [ ! "$SKIP_INACTIVITY_POLL" ]; then   
    SKIP_INACTIVITY_POLL=0               
fi    

echo "Encryption type: $ENCRYPTION_TYPE";
echo "htmode: $HTMODE";

NET_ID="qosldrd"
WIFI_DEV="radio0"
WIFI_KEY="qosldrd123"

uci -q batch << EOF
delete wireless.${NET_ID}
set wireless.${WIFI_DEV}.htmode=${HTMODE}
set wireless.${NET_ID}=wifi-iface
set wireless.${NET_ID}.device=${WIFI_DEV}
set wireless.${NET_ID}.mode=ap
set wireless.${NET_ID}.network=lan
set wireless.${NET_ID}.ssid=${NET_ID}
set wireless.${NET_ID}.encryption=${ENCRYPTION_TYPE}
set wireless.${NET_ID}.hidden='1'
set wireless.${NET_ID}.key=${WIFI_KEY}
set wireless.${NET_ID}.skip_inactivity_poll=$SKIP_INACTIVITY_POLL
set wireless.${NET_ID}.disassoc_low_ack=$DISASSOC_LOW_ACK
commit wireless
delete dhcp.${NET_ID}
set dhcp.${NET_ID}=dhcp
set dhcp.${NET_ID}.interface=${NET_ID}
set dhcp.${NET_ID}.start=100
set dhcp.${NET_ID}.limit=150
set dhcp.${NET_ID}.leasetime=1h
set dhcp.${NET_ID}.netmask=255.255.255.0
commit dhcp
EOF

/etc/init.d/network reload
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart