if mail-server is local skip to [1.2](#1.2)

## 1.1 fetch mail from remote machine

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

ideally cron (or a task-scheduler) does this automatically. after initial-setup jump right to [3](#3)

## <a id=1.2></a>1.2 place messages on the filesystem

location is not important as data is converted to RDF and written to a location derived from Message-ID. we like one directory per day -  our server has a shortcut to [today](http://m.whats-your.name/today)'s directory

example **.procmailrc**:

``` sh
D=$HOME/.mail/`date +%Y/%m/%d`
MKDIR=`test -d $D || mkdir -p $D`
DEFAULT=$D

```

## 1.3 make files available to all devices

optional, but redundancy-purposes, your mail can be synchronized all of your devices with

## 2 serve messages

for the sake of demonstration, the [daemon](http://src.whats-your.name/pw/) is already running at **/var/www**. 


``` sh
ln -s /home/archiver/.mail /var/www/domain/localhost/

```
or combine with [1.2](#1.2) by changing **$HOME** in procmailrc to **/var/www/domain/localhost/**

## <a id=3></a>3 browse messages

messages are automatically indexed
