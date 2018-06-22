#!/bin/sh
while true
do
    r .conf/hyper.u fetchFeeds
    r .conf/twitter.com.bu twitter
    date
    sleep 42m
done
