if mail-server is local skip to [1.2](#1.2)

## 1.1 fetch mail from remote machine

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

one may configure cron (task-scheduler) to do this regularly

## <a id=1.2></a>1.2 place messages on the filesystem

file-location is not important as data is converted to RDF and written at a location derived from the Message-ID. we like one directory per day -  our server has a special shortcut to [today](http://m.whats-your.name/today)'s directory, which is the closest thing to an Inbox:

example **.procmailrc**:

``` sh
D=$HOME/.mail/`date +%Y/%m/%d`
MKDIR=`test -d $D || mkdir -p $D`
DEFAULT=$D

```

## 1.3 make files available on all devices

## 2 link msg-directory to a servable location

for the sake of demonstration, the [daemon](http://src.whats-your.name/pw/) is running at **/var/www**


``` sh
ln -s /home/archiver/.mail /var/www/domain/localhost/

```
or combine with the previous step, change **$HOME** in procmailrc to **/var/www/domain/localhost/**