# webmail-system

make messages visible to the server, e.g.:

``` sh
cd /var/www
ln -s /home/subscriber/.mail/2016 domain/localhost
```

browse messages. for example today's messages:

``` sh
$ chromium localhost/today
```

## URL structure
* person and message resources appear in **/address**
* a dynamic-handler at **/thread** finds discussions
* full-text-index is in **/index**
* RDF-transcodes in **/cache**

to wipe out all content derived from browsing the original message-files:

``` sh
rm -rf address cache index
```

RDF URIs are deterministically minted from the Message-ID. original message-files aren't pointed to and can be removed after being "seen" by the server:

``` sh
rm -rf ~/.mail/2016/01
```

to really kill messages you'd have to delete all of the above plus flush [tabulator](https://github.com/linkeddata/tabulator)'s know-ledgebase and possibly delete on other machines synced with [rsync](http://linux.die.net/man/1/rsync) or [syncthing](https://syncthing.net/) or [btsync](https://www.getsync.com/) or [gluster](http://www.gluster.org/) or they'll haunt you forever. it's by design that messages are at least a little hard to delete. ultimately the database is the filesystem, opening up replication to however you prefer - we are just adding a layer of rewriting and caching

