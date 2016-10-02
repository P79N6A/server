this describes a full solution for email with everything except [viewing](../../ruby/message.mail.rb.html) delegated to 3rd-party tools.

## fetch mail

only required if SMTP isn't directly-delivering to a machine

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

either cron/task-schedule it or run **getmail** manually

### which machine should run this?

phone as designated-fetcher is one idea, it's probably the most-likely to be on and with you - laptops/tablets/desktops can synchronize for backup/redundancy when up. if youre going to fetch from multiple devices onto a distributed-filesystem, adjust **MSGPREFIX** in .procmailrc to something like msg.hostA. msg.hostB. - multiple copies of source-message from different hosts will be deduplicated on Message-ID, you just want to avoid name-collision of source files

install getmail and/or procmail via your system's package-manager and check out the sample conf-files in this directory

## write messages to files

location or layout isn't important - whatever you prefer. day-dirs are a simple solution. if used, a redirect-handler at [/today](http://m.whats-your.name/today) (bookmark/iconify this) takes you to something approximating an inbox

**.procmailrc**

``` sh
D=$HOME/.mail/`date +%Y/%m/%d`
MKDIR=`test -d $D || mkdir -p $D`
DEFAULT=$D

```

no need to go crazy with procmail labels, though you can

## network other devices

while a VPS or dedicated server likely has a stable network, phones and laptops/tablets don't. VPN options include:

* [OpenVPN](https://openvpn.net/)

or mesh/peer-to-peer VPN:

* [peervpn](http://www.peervpn.net/)
* [tinc](http://www.tinc-vpn.org/)
* [n2n](https://github.com/meyerd/n2n)

or direct networking on built-in Bluetooth, USB or HostAP (Wi-Fi) interfaces

## file-redundancy across devices

now that your devices are networked, you'll want your files everywhere

* [Gluster](http://www.gluster.org/)
* [BTSync](https://wiki.archlinux.org/index.php/BitTorrent_Sync)
* [Syncthing](https://syncthing.net/)
* [Unison](https://www.cis.upenn.edu/~bcpierce/unison/)

or if you hate automation, these scripts using [rsync](https://rsync.samba.org/):

``` sh
# on laptop
rsync phone:.mail . && getmail && rsync .mail phone:
# on phone
rsync laptop:.mail . && getmail && rsync .mail laptop:
```

put just the raw-msgs dir on the distributed-fs, or also address/ (dir at server-root caching transcoded-RDF) 

## serve messages to browser

if messages arent visible to the server, make it so

``` sh
ln -s /home/archiver/.mail /var/www/domain/localhost/

```

launch a server

``` sh
foreman start
```

## read messages

now that messages are appearing, they can be browsed

``` sh
$ chromium localhost/today
```

devices can connect to either their webserver or other webservers on the VPN. to put private mail on servers on the global internet, auth-layers are available as Rack middleware. using a WebID/ACL frontend of ldnode is another possibility

## write messages

reply-pointers are **mailto** URIs. Android/iOS offer a built-in mail-composition UI. for X11/Wayland here's an [example config](mailto). modern-browsers allow handling by web-services in addition to native-apps