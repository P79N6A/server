WHAT
a HTTP interface to mail and news (files) or a filesystem in general

JSON format - optional alternative in addition to RDF formats (if you JUST want those, see https://github.com/ruby-rdf/rdf-ldp)
a mini-RDF in JSON with no blank-nodes or special-syntax literal-datatypes/languages (just JSON-native types)
despite the omissions, being able to trivially-implement in new languages is one advantage,
as is reading thousands of files for a sub-second response via C/stdlib JSON-parser vs pure-ruby RDF-parsers,
and a model allowing trivial "hash merge" into RAM without mapping/expansion/rewriting steps of JSON-LD (our
predicate URIs are always fully expanded, no searching inside strings for base-URI prefixes, no mapping-frames)

everything is a Resource, with a URI. our resource-class is named R, one can be instantiated with R() or R[] syntax

REQUISITES
Debian http://www.debian.org/
 apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
Voidlinux http://www.voidlinux.eu/
 xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments && gem install bundler

INSTALL
 cd ruby
 bundle install     # install packages we depend on
 ruby install       # install this package
 cd ..
 cp conf/Procfile . # deamon configuration, edit to taste

USE
 foreman start

TIPS
 files go in in domain/hostname/path/to/file and/or path/to/file, latter visible to any host

 to listen on port 80/443 as a non-root user: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
