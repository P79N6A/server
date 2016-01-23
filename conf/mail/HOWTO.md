this describes a full solution to personal email, all steps may not be needed in your use-case. everything except browsing is delegated to 3rd-party tools. 

## 1.1 fetch mail from remote machine(s)

only required if SMTP isn't directly-delivering to a machine..

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

either cron/task-schedule or run **getmail** manually

### which machine should run this?

phone as designated-fetcher is good, it's the most-likely of all your devices to be on and with you (probably). laptops/desktops can synchronize for backup/redundancy when up

### i'm putting getmail in cron on all my devices, deal with it

you're at risk of filename-collisions, unless you rule it out somehow:

* add deviceID to the procmailrc path-template (server will de-dupe later, you just don't want to clobber msg.AAA with a different msg.AAA file)
* use global locking or a consensus-algorithm to select a master

### i don't have getmail on my phone

you probably havent installed a userspace yet. a simple way on Android is untarring a Gentoo or VoidLinux rootfs onto /data and chrooting into it, after bindmounting {dev,proc,sys}. Termux (in FDroid-store) keeps getting better, and may have these tools as well

## <a id=1.2></a>1.2 write messages to files

location or layout isn't important. day-dir is a simple solution

**.procmailrc**:

``` sh
D=$HOME/.mail/`date +%Y/%m/%d`
MKDIR=`test -d $D || mkdir -p $D`
DEFAULT=$D

```

## 1.3.1 network other devices

while your VPS or dedicated server, if you have one, likely has a stable address, your phone and laptops/tablets probably dont. a personal VPN is required. conventional offerings include

* [OpenVPN](https://openvpn.net/)

without a centralized server, a mesh/peer-to-peer VPN can be used, such as:

* peervpn
* tinc
* n2n


## 1.3.2 make files available on all devices

replicate files to all your devices/servers with a synchronization-tool or distributed-fs

* [Gluster](http://www.gluster.org/)
* [BTSync](https://wiki.archlinux.org/index.php/BitTorrent_Sync)
* [rsync](https://rsync.samba.org/)
* [SCP](https://en.wikipedia.org/wiki/Secure_copy)
* [Syncthing](https://syncthing.net/)
* [Unison](https://www.cis.upenn.edu/~bcpierce/unison/)

a really-simple solution w/o automated fetching or sync:

``` sh
# on laptop
rsync phone:.mail . && getmail && rsync .mail phone:
# on phone
rsync laptop:.mail . && getmail && rsync .mail laptop:
```

this fetches existing files to sync, and pushes new stuff to the other device

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

laptop can either connect to phone's webserver over VPN (or vice-versa), or their own server looking at local mirror of mail-files or remote files over NFS
## 4 write messages

browser invokes your handler of choice for **mailto**-URIs. Android/iOS offer a built-in mail-composition app. on X11/Wayland, [mailto](mailto) can be a shell-script
