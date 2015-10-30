a mini-RDF in JSON with no blank-nodes or special-syntax literal datatypes/languages (just JSON-native types)
despite the omissions, being able to trivially-implement in new languages is one advantage,
as is reading thousands of files for a sub-second response via C/stdlib JSON-parser vs pure-ruby RDF-parsers,
and a model allowing trivial "hash merge" into RAM without mapping/expansion/rewriting steps of JSON-LD (our
predicate URIs are always fully expanded, no searching inside strings for base-URI prefixes etc)

original use-case was a HTTP interface to locally-cached mail and news. it predates RDF.rb and maybe even Rails.
first we erased manual sprintf()'ing to a socket for Rack when that came along, then later a RDF::Reader was added
to parse our JSON into real RDF Graphs. next i'll proably delete the daemon and use lamprey from https://github.com/ruby-rdf/rdf-ldp

our HTTP server uses a JSON-cache of the non-RDF for speed, and type-specific indexer-hooks are run on cache-miss (file changed) events

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
 # mail-paths start with /address or /thread so just those paths could be sent in, etc..
