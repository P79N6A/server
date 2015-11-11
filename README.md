#pw

HTTP interface to a filesystem to be used as a zero-configuration webserver for mail and news (message/rfc2822, RSS, Atom) among other things

## MIMEs
an optimized JSON format, alternative to RDF formats, HTML and plaintext is used throughout:

### JSON
a subset of RDF with no blank-nodes or special-syntax literal-datatypes/languages, just JSON-native literals

data is arranged for URI key-lookup and merge into a memory Hash-table, w.o mapping/expansion/rewriting:

predicate URIs are stored in full, no searching inside strings for base-URI prefixes or *-LD mapping-frames

### URI list
files of one URI per line. used as primitive indexes and triple building-blocks. about as trivial as parsing can get


## API
everything is a Resource with a URI. the Resource-class is named R, instantiated in R() or R[] syntax

our resource class is just an identifier with one instance-variable, an environment (inherited from a HTTP request)

### RDF compatibility

#### Resource
R is a subclass of RDF::URI and inherits its methods. we added a bidirectional-mapping from URIs to POSIX fs-paths


#### JSON format
an RDF::Reader interface is defined. there is no Writer defined, as it cant roundtrip full RDF. for full RDF we recommend [Turtle](http://www.w3.org/TeamSubmission/turtle/)

### Search
on-line search is available via [Groonga](http://groonga.org/) and grep. no server-side crawlers: you must GET to trigger indexing

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
