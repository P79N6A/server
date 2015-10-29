WHAT  a content-management system, web-mail, newsreader, implemented by way of
a www-daemon, backed by a filesystem. a cached conversion to RDF ensues, unless your data is already RDF
if your data is always RDF you can skip this software entirely and use https://github.com/ruby-rdf/rdf-ldp
there's a RDF::Reader class for our intermediary format which you could use with other apps or servers

our intermediary format is "almost" RDF built just using JSON and Hash classes, omitting blank-nodes and advanced literal datatypes/languages (just JSON-native types)

REQUISITES
Debian http://www.debian.org/
 apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments

Voidlinux http://www.voidlinux.eu/
 xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments
 gem install bundler

 for mail, may also want msmtp, procmail, getmail (see conf/mail/)

INSTALL
 cd ruby
 bundle install # install ruby libraries
 ruby install # symlink source-dir to library-path

USE
 cd ..
 cp conf/Procfile .
 foreman start

TIPS
port 80/443 non-root: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
      >1024 nginx + apache configuration examples in conf/
