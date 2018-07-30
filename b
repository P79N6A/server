#!/bin/sh
export https_proxy=https://192.168.43.1:8080
export http_proxy=http://192.168.43.1:8080
export no_proxy=`cat ~/src/pw/config/proxy.domains | tr "\n" ","`
chromium
