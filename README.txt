REQUISITES
#debian - http://www.debian.org/
 apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
#void   - http://www.voidlinux.eu/
 xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments
 gem install bundler

INSTALL
 cd ruby
 bundle install # install ruby libraries
 ruby install # symlink source-dir to library-path

USE
 cd ..
 cp conf/Procfile .
 foreman start

TIPS
port 80/443 (non-root standalone) setcap cap_net_bind_service=+ep $(realpath `which ruby`)
      >1024 "behind apache/nginx" configuration samples in conf/
