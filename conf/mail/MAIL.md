# webize mail

make messages visible to the server, e.g.:

``` sh
ln -s ~/.mail/2016 domain/localhost
```

browse messages. for example today's messages:

``` sh
$ chromium localhost/today
```

## URL structure
* author and message **resources** and indexed message-**containers** under **/address**
* dynamic-handler at **/thread** reconstructs discussions

to wipe data generated while browsing rfc2822-message files

``` sh
rm -rf address cache index
```

RDF URIs are deterministically minted from the Message-ID. message-files can be removed after being "seen" by the server

``` sh
rm -rf ~/.mail
```

messages can be cached client-side by [browsing](https://github.com/linkeddata/tabulator) them and on other devices by synchronizing files with [rsync](http://linux.die.net/man/1/rsync), [syncthing](https://syncthing.net/), [btsync](https://www.getsync.com/), [gluster](http://www.gluster.org/) etc
