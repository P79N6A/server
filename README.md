#pw

[HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to a [filesystem](http://www.multicians.org/fjcc4.html) which can be used as a [zero-configuration](http://suckless.org/philosophy) webserver for [mail](http://m.whats-your.name) and [news](https://github.com/majestrate/nntpchan) ([message/rfc2822](http://www.faqs.org/rfcs/rfc2822.html), [RSS](http://web.resource.org/rss/1.0/spec), [Atom](https://tools.ietf.org/html/rfc4287))

## MIMEs

### JSON
a subset of [RDF](https://ruby-rdf.github.io/) with no [blank-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just [JSON](http://www.json.org/)-native literals

data is arranged for [URI](https://www.ietf.org/rfc/rfc1630.txt) key-lookup and [merge](ruby/JSON.rb.html) into a memory [Hash](http://docs.ruby-lang.org/en/2.0.0/Hash.html)-table, w.o [mapping/expansion/rewriting](http://www.w3.org/TR/json-ld-api/#context-processing-algorithms):

[predicate](http://www.w3.org/TR/rdf11-concepts/#dfn-predicate) [URIs](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) are stored in full, no searching inside strings for [base-URI](https://annevankesteren.nl/2005/08/base-examples) prefixes or [*-LD mapping-frames](http://json-ld.org/spec/latest/json-ld-framing/)

### URI list
files of one [URI per line](http://amundsen.com/hypermedia/urilist/). used as primitive [indexes](https://en.wikipedia.org/wiki/Database_index) and [triple](http://stackoverflow.com/questions/273218/whats-an-rdf-triple) building-blocks. about as trivial as [parsing](https://github.com/RubenVerborgh/N3.js#parsing) can get

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
