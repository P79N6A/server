WAT
this is in the process of being deleted. you probably want https://github.com/ruby-rdf/rdf-ldp

$ cd ruby

REQUISITES
# debian http://www.debian.org/
 apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
# void   http://www.voidlinux.eu/
 xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments
 gem install bundler

INSTALL
 bundle install # install ruby libraries
 ruby install # symlink source-dir to library-path

USE
$ cd ..
$ cp conf/Procfile . # tweak configuration as desired
$ foreman start
port: 80/443 (standalone)  setcap cap_net_bind_service=+ep $(realpath `which ruby`)
      >1024  (behind apache/nginx/lighttpd/etc) configuration samples in conf/
