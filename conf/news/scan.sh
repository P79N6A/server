#!/bin/sh
rtl_fm -f 927.0625M -f 162.55 -l 42 -M fm -g 30 | pacat --format=s16le --rate=24000 --channels=1
