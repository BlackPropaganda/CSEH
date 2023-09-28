#!/bin/bash

#
# Initiates remote proxy and addresses
#

autossh_host="username@1.1.1.1"
autossh_host_ip=$(echo $autossh_host | cut -d '@' -f2)
autossh_port="22"


# Pineapple IP address to bind Socks5 to (br-lan)
# THIS BINDS THE PROXY TO ALL LOCAL ADDRESSES ON ALL INTERFACES
bind_address="0.0.0.0"
proxy_port="1080"

# pineapple interface connected to internet via client mode or USB ethernet.
interface="wlan2"

#
# the following was slightly modified from dark_pyrro (the legend) via:
# https://codeberg.org/dark_pyrro/Packet-Squirrel-autossh/src/branch/main/payload.sh
#

# waiting until eth1 acquires IP address
while ! ifconfig "$interface" | grep -qi "inet addr"; do sleep 1; done

# logging
echo -e "starting ssh server.\n" >> /root/remote/debug.txt

# starting sshd and waiting for process to start
/etc/init.d/sshd start
until netstat -tulpn | grep -qi "sshd"
do
    sleep 1
done

# stopping autossh
/etc/init.d/autossh stop

#
# Much like the SSH server, AutoSSH has a configuration file. This
# needs to be configured to support this connection as a daemon.
#
# Create a "fresh template" for the autossh configuration
# Starting with an empty autossh file in /etc/config
# isn't something that uci is very fond of
echo "config autossh" > /etc/config/autossh
echo "        option ssh" >> /etc/config/autossh
echo "        option enabled" >> /etc/config/autossh


echo -e "starting autossh.\n" >> /root/remote/debug.txt

# UCI configuration and commission
uci set autossh.@autossh[0].ssh="-i /root/.ssh/id_rsa -D "$bind_address":"$proxy_port" "$autossh_host" -p "$autossh_port" -N -T"
uci set autossh.@autossh[0].enabled="1"
uci commit autossh

# starting autossh
/etc/init.d/autossh start

until netstat | grep -i "ESTABLISHED" | grep -qi "$autossh_host_ip:ssh"
do
    sleep 2
    echo "Establishing Connection..."
done

echo -e "Connection Established. Starting Socks5 proxy on: "$bind_address"\n" >> /root/remote/debug.txt
echo -e "Connection Established. Starting Socks5 proxy on: "$bind_address"\n" >> /root/remote/debug.txt

# Happy Hunting.
