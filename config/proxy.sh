#!/bin/sh
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner 10084 --dport 80 -j REDIRECT --to-ports 8000
iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner 10084 --dport 443 -j REDIRECT --to-ports 8888
