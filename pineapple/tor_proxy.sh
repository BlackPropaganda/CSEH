#!/bin/bash

# prereqs:
# opkg update
# opkg install tor

# Configure Tor client
cat << EOF > /etc/tor/custom
AutomapHostsOnResolve 1
AutomapHostsSuffixes .
VirtualAddrNetworkIPv4 172.16.0.0/12
VirtualAddrNetworkIPv6 [fc00::]/8
DNSPort 0.0.0.0:9053
DNSPort [::]:9053
TransPort 0.0.0.0:9040
TransPort [::]:9040
SocksPort 172.16.42.1:9100
SocksPolicy accept 172.16.42.0/24
EOF

cat << EOF > /etc/tor/torrc
SocksPort 172.16.42.1:9050
# Makes entire br-lan tor socks accessible.
# SocksPolicy accept 172.16.42.0/24
DataDirectory /var/lib/tor
User tor
EOF

# uci del_list tor.conf.tail_include="/etc/tor/custom"
# uci add_list tor.conf.tail_include="/etc/tor/custom"
uci commit tor
/etc/init.d/tor restart

# restart services
# /etc/init.d/log restart; /etc/init.d/firewall restart; /etc/init.d/tor restart