``` sh
cd ruby
bundle install     # install packages we depend on
ruby install       # install this package
cd ..
ln conf/Procfile . # deamon configuration, edit to taste
```

* files go in domain/$HOST/path/to/file or path/to/file
* daemon can run elsewhere, link or copy [js/](js/) and [css/](css/) directories to [server-root](.)
* one way to listen on port 80/443 as a non-root user:

``` sh
setcap cap_net_bind_service=+ep $(realpath `which ruby`)
```

## RUN
``` sh
foreman start
```