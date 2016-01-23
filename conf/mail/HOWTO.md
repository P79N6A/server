this describes my full solution to email, all steps may not be needed in your use-case. everything except browsing is delegated to 3rd-party tools. 

## 1.1 fetch mail from remote machine(s)

only required if SMTP isn't directly-delivering to a machine

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

either cron/task-schedule it or run **getmail** manually

### which machine should run this?

phone as designated-fetcher is good, it's the most-likely of all your devices to be on and with you (probably). laptops/desktops can synchronize for backup/redundancy when up

### i'm putting getmail in cron on all my devices, deal with it

you're at risk of filename-collisions, unless you rule it out somehow:

* add deviceID to the procmailrc path-template (server will de-dupe later, you just don't want to clobber msg.AAA with a different msg.AAA file)
* use global locking or a consensus-algorithm to select a master

### i don't have getmail on my phone

you probably havent installed a userspace yet. a simple way on Android is untarring a [Gentoo](//gentoo.org) or [VoidLinux](//voidlinux.eu) rootfs onto /data and chrooting into it, after bindmounting {dev,proc,sys}. Termux (in FDroid-store) keeps getting better, and may have these tools as well

## <a id=1.2></a>1.2 write messages to files

location or layout isn't important. day-dir is a simple solution

**.procmailrc**

``` sh
D=$HOME/.mail/`date +%Y/%m/%d`
MKDIR=`test -d $D || mkdir -p $D`
DEFAULT=$D

```

## 1.3.1 network other devices

while a VPS or dedicated server likely has a stable network, phones and laptops/tablets don't. VPN options include:

* [OpenVPN](https://openvpn.net/)

or mesh/peer-to-peer VPN:

* [peervpn](http://www.peervpn.net/)
* [tinc](http://www.tinc-vpn.org/)
* [n2n](https://github.com/meyerd/n2n)

or direct networking on built-in Bluetooth, USB or HostAP/wifi interfaces

## 1.3.2 redundancy across all devices

now that your devices are networked, you'll want your files everywhere

* [Gluster](http://www.gluster.org/)
* [BTSync](https://wiki.archlinux.org/index.php/BitTorrent_Sync)
* [rsync](https://rsync.samba.org/)
* [SCP](https://en.wikipedia.org/wiki/Secure_copy)
* [Syncthing](https://syncthing.net/)
* [Unison](https://www.cis.upenn.edu/~bcpierce/unison/)

or if you hate automation, these scripts:

``` sh
# on laptop
rsync phone:.mail . && getmail && rsync .mail phone:
# on phone
rsync laptop:.mail . && getmail && rsync .mail laptop:
```

## 2 serve messages

if messages arent visible to the server, make it so:

``` sh
ln -s /home/archiver/.mail /var/www/domain/localhost/

```

launch a server

``` sh
foreman start
```

## <a id=3></a>3 browse messages

now that messages are appearing, they can be browsed

``` sh
$ chromium localhost/today
```

## 4 write messages

browser invokes your handler of choice for **mailto**-URIs. Android/iOS offer a built-in mail-composition app. on X11/Wayland, [mailto](mailto) can be a shell-script
