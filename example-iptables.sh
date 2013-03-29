#!/bin/sh
# Sample iptables configuration

IPT="/sbin/iptables"

###########
# CLEANUP #
###########

# clean all chains
$IPT -F
$IPT -F -t nat
$IPT -F -t mangle
$IPT -F -t raw

# delete all user chains
$IPT -X
$IPT -X -t nat
$IPT -X -t mangle
$IPT -F -t raw

##################
# DEFAULT POLICY #
##################

$IPT -P FORWARD DROP
$IPT -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -P INPUT DROP
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -P OUTPUT ACCEPT

#########
# INPUT #
#########

# allow icmp echo request(ping)
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
# allow some service messages
$IPT -A INPUT -p icmp --icmp-type fragmentation-needed -j ACCEPT
# input from localhost
$IPT -A INPUT -i lo -j ACCEPT
# input from local network
$IPT -A INPUT -i $IFACE_LOCAL_NET -j ACCEPT

##############
# FORWARDING #
##############

# enable forwarding
echo "1" > /proc/sys/net/ipv4/ip_forward
# allow forwarding from local netwprk to internet
$IPT -A FORWARD -s $NET_LOCAL -o $IFACE_INET -j ACCEPT

#######
# NAT #
#######

# SNAT from local network to internet
$IPT -t nat -A POSTROUTING -s $NET_LOCAL -o $IFACE_INET -j MASQUERADE

# DNAT: redirect 8080 internet port to 8080 port on local server
$IPT -t nat -A PREROUTING -i $IF_INET -d $IP_INET -p tcp --dport 8080 -j DNAT --to-destination $IP_LOCAL_SRV:8080
$IPT -A FORWARD -i $IF_INET -d $IP_LOCAL_SRV -p tcp --dport 8080 -j ACCEPT
