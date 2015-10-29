WHAT? filesystem-browsing via RDF-conversion, for email, newsreading, archival

a subset of RDF in JSON is our intermediary format,
sans blank-nodes and advanced literal datatypes/languages (just JSON-native types).
despite the omissions, being able to trivially-implement in new languages is one advantage,
as is loading thousands of files in a sub-second response thanks to native-stdlib JSON-parsers
and trivial merging into RAM without the mapping/expansion steps of JSON-LD or pure-ruby parsers

our daemon populates a cache of non-RDF in this intermediary format, and RDF::Reader implementations
for the original MIMEs and the intermediary format allows reading from say https://github.com/ruby-rdf/rdf-ldp

REQUISITES
Debian http://www.debian.org/
 apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments

Voidlinux http://www.voidlinux.eu/
 xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments
 gem install bundler

INSTALL
 cd ruby
 bundle install # install ruby libraries
 ruby install # symlink source-dir to library-path

USE -> files in domain/hostname/path/to/file and/or path/to/file, latter visible to any host
 cd ..
 cp conf/Procfile .
 foreman start # listen on port 80/443 as non-root user: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
 # you can use nginx/apache do <1024 and bind to a high-port. or throw us behind a 404-handler on a LDP server, or..
 # mail-URIs start with /address or /thread so just those paths could be sent in, etc..
