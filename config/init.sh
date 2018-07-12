#!/bin/sh
iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner 10095 --dport 443 -j REDIRECT --to-ports 8888
mount /dev/block/sda2 /data/mnt && cd /data/mnt
mount -o bind /dev dev
mount -o bind /dev/pts dev/pts
mount -o bind /proc proc
mount -o bind /sys sys
chroot . /usr/sbin/sshd
