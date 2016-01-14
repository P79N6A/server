if mail-server is local skip to [1.2](#1.2)

## 1.1 fetch mail from remote machine

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

one may configure cron (task-scheduler) to do this regularly

## <a id=1.2></a>1.2 place messages on the filesystem

file location is not important as they're nondestructively written to a new location derived from Message-ID. we like one directory per day - it keeps dirs from getting too huge and our server has a special shortcut to today's directory, which is the closest thing our server provides to an Inbox:

example **.procmailrc**:

``` sh
D=$HOME/.mail/`date +%Y/%m/%d`
MKDIR=`test -d $D || mkdir -p $D`
DEFAULT=$D

```
