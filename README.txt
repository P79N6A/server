WHAT?
due to wanting to get something working right away, before Ruby had an RDF library,
a native format of "almost" RDF built on JSON was invented,
sans blank-nodes and advanced literal datatypes/languages (just JSON-native types).
despite the omissions, being able to trivially-implement in new languages is one advantage,
as is swiftly-loading thousands of files for a sub-second response thanks to native JSON-parsers and jettisoned complexity

files go in domain/hostname/path/to/file, or path/to/file, the latter visible on any host

we try to behave like a LDP server. see: https://github.com/ruby-rdf/rdf-ldp
our JSON-format and Atom/RSS feeds have a RDF::Reader class, to be used in apps/servers like the one above
or you can use our daemon for a zero-configuration web-mail, newsreader and filesystem-browser
directly on port 80/443 as a non-root user: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
or behind apache or nginx or some other front-end

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
