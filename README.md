#pw

[HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to a [filesystem](http://www.multicians.org/fjcc4.html) to be used as a zero-configuration webserver for [mail](http://m.whats-your.name) and [news](https://github.com/majestrate/nntpchan) (message/rfc2822, RSS, Atom) among other things

## MIMEs

### JSON
a subset of [RDF](https://ruby-rdf.github.io/) with no [blank-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just JSON-native literals

data is arranged for URI key-lookup and merge into a memory Hash-table, w.o mapping/expansion/rewriting:

predicate URIs are stored in full, no searching inside strings for base-URI prefixes or *-LD mapping-frames

### URI list
files of one URI per line. used as primitive indexes and triple building-blocks. about as trivial as parsing can get


## API
everything is a Resource with a URI. the Resource-class is R, instantiated in R() or R[] syntax

our resource class is just an identifier with one instance-variable, an environment (inherited from a HTTP request)

### RDF-compatibility

#### Resource
R is a subclass of RDF::URI and inherits its methods. we added a bidirectional-mapping from URIs to POSIX fs-paths


#### JSON format
an RDF::Reader interface is defined. there is no Writer defined, as it cant roundtrip full RDF. for full RDF we recommend [Turtle](http://www.w3.org/TeamSubmission/turtle/)

### Search
on-line search is available via [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). no server-side crawlers: you must [GET](man/GET.html) to trigger indexing

## REQUISITES

### [Debian](http://www.debian.org/)
``` sh
apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
```

### [Voidlinux](http://www.voidlinux.eu/)
``` sh
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments && gem install bundler
```
## INSTALL
``` sh
cd ruby
bundle install     # install packages we depend on
ruby install       # install this package
cd ..
cp conf/Procfile . # deamon configuration, edit to taste
```

## USE
``` sh
foreman start
```

## TIPS
* files go in ./domain/$HOST/path/to/file or ./path/to/file
* server can be run elsewhere, link or copy jss/ and css/ directories to server-root
* howto listen on port 80/443 as a non-root user: setcap cap_net_bind_service=+ep $(realpath \`which ruby\`)
