#!/bin/sh
while true
do
    R .conf/hyper.u fetchFeeds
    R .conf/twitter.com.bu twitter
    date
    sleep 30m
done
