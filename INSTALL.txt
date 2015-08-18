
$ cd ruby
$ ruby install   # link source to $sitelibdir

DEPENDENCIES
$ apt-get install ruby bundler libssl-dev libgit2-dev libxml2-dev libxslt1-dev pkg-config                            # debian <http://www.debian.org/>
$ xbps-install base-devel ruby ruby-devel libgit2-devel libxml2-devel libxslt-devel source-highlight python-Pygments # void <http://www.voidlinux.eu/>

$ gem install bundler
$ bundle install      # ruby libraries

USE
$ cd ..
$ cp conf/Procfile . # tweak as desired for base server-engine and IP settings
$ foreman start

port 80/443: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
      >1024: standalone or behind apache/nginx/lighttpd, samples in conf/

REPL
$ irb -rww

CLEAN
$ rm -rf cache index
