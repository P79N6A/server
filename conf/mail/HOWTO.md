as much as possible, tasks are delegated to 3rd-party tools - much of this HOWTO consists of pointers to them.

## 1.1 fetch mail from remote machine

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

ideally cron (or a task-scheduler) does this automatically. after initial-setup jump right to [3](#3)

## <a id=1.2></a>1.2 put messages on the filesystem

location isn't important as data is rewritten to a location derived from Message-ID. one directory per day is simple enough:

**.procmailrc**:

``` sh
D=$HOME/.mail/`date +%Y/%m/%d`
MKDIR=`test -d $D || mkdir -p $D`
DEFAULT=$D

```

## 1.3 make files available on all devices

for redundancy-purposes, files are replicated to other devices and servers with one of:

* [Gluster](http://www.gluster.org/)
* [BTSync](https://wiki.archlinux.org/index.php/BitTorrent_Sync)
* [rsync](https://rsync.samba.org/)
* [SCP](https://en.wikipedia.org/wiki/Secure_copy)
* [Syncthing](https://syncthing.net/)
* [Unison](https://www.cis.upenn.edu/~bcpierce/unison/)

## 2 serve messages

for the sake of demonstration, a [daemon](http://src.whats-your.name/pw/) is launched at **/var/www**. 


``` sh
ln -s /home/archiver/.mail /var/www/domain/localhost/

```

## <a id=3></a>3 read messages

now that messages are being delivered and visible to the server, they can be browsed

``` sh
$ chromium localhost/today
```

## 4 write messages

browser invokes your handler of choice for **mailto**-URIs. Android/iOS offer a built-in mail-composition app. on X11/Wayland, [mailto](mailto) can be a shell-script
