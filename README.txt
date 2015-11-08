pw - a HTTP interface to the filesystem & zero-configuration server for mails and news (message/rfc2822, RSS, Atom)

an optimized JSON format, alternative to RDF formats, HTML and plaintext is used throughout:
mini-RDF in JSON with no blank-nodes or special-syntax literal-datatypes/languages (just JSON-native types).
despite the omissions vs "Full RDF", being able to trivially-implement in new languages is one advantage
as is handling thousands of files for sub-second response via C/stdlib JSON-parser vs pure-ruby RDF-parsers.
data is arranged for URI key-lookup and merge into a memory Hash-table, w.o mapping/expansion/rewriting steps:
predicate URIs are stored in full, no searching inside strings for base-URI prefixes or *-LD mapping-frames

everything is a Resource with a URI. our Resource-class is named R, instantiated in R() or R[] syntax
the URI is a subclass of RDF::URI and JSON-format has an RDF::Reader, for responses in (Turtle) RDF on request

on-line search is available via Groonga and grep. no server-side crawlers: you must GET to trigger indexing

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
 - files go in ./domain/$HOST/path/to/file or ./path/to/file
 - server can be run elsewhere, link or copy jss/ and css/ directories to server-root
 - howto listen on port 80/443 as a non-root user: setcap cap_net_bind_service=+ep $(realpath `which ruby`)
