#!/bin/sh
while true
do
    r .conf/feeds.u fetchFeeds
    date
    sleep 8h
done
