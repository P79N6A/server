if mail-server is local skip to [1.2](#1.2)

## 1.1 fetch mail from remote machine

* [OfflineIMAP](http://offlineimap.org/)
* [getmail](http://pyropus.ca/software/getmail/)

one may configure cron (task-scheduler) to do this regularly

## <a id=1.2></a>1.2 place messages on the filesystem

message location does not matter here, they're nondestructively transcoded to RDF at new location derived from Message-ID value. we like one directory per day.
