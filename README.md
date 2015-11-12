# pw

[HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to a [filesystem](http://www.multicians.org/fjcc4.html) which can be used as a [zero-configuration](http://suckless.org/philosophy) webserver for [mail](http://m.whats-your.name) and [news](https://github.com/majestrate/nntpchan) ([message/rfc2822](http://www.faqs.org/rfcs/rfc2822.html), [RSS](http://web.resource.org/rss/1.0/spec), [Atom](https://tools.ietf.org/html/rfc4287))

## MIMEs

### JSON
a [subset](https://en.wikipedia.org/wiki/Subset) of [RDF](https://ruby-rdf.github.io/) with no [blank-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just [JSON](http://www.json.org/)-native literals

data is arranged for [URI](https://www.ietf.org/rfc/rfc1630.txt) key-lookup and [merge](ruby/JSON.rb.html) into a memory [Hash](http://docs.ruby-lang.org/en/2.0.0/Hash.html)-table, w.o [mapping/expansion/rewriting](http://www.w3.org/TR/json-ld-api/#context-processing-algorithms):

[predicate](http://www.w3.org/TR/rdf11-concepts/#dfn-predicate) [URIs](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) are stored in full, no searching inside strings for [base-URI](https://annevankesteren.nl/2005/08/base-examples) prefixes or [*-LD mapping-frames](http://json-ld.org/spec/latest/json-ld-framing/)

### URI lists
files of one [URI per line](http://amundsen.com/hypermedia/urilist/). used as primitive [indexes](https://en.wikipedia.org/wiki/Database_index) and [triple](http://stackoverflow.com/questions/273218/whats-an-rdf-triple) building-blocks. about as trivial as [parsing](https://github.com/RubenVerborgh/N3.js#parsing) can get

## API
everything is a [resource](https://en.wikipedia.org/wiki/Web_resource) with a [URI](https://tools.ietf.org/html/rfc3986). the Resource-class is [R](ruby/names.rb.html), instantiated in R() or R[] syntax

our [resource](http://stackoverflow.com/questions/25737584/subclassof-and-instance-of-rdf-rdfsclass/25743530#25743530) class is an [identifier](https://en.wikipedia.org/wiki/Identifier) with one [instance-variable](http://ruby-doc.com/docs/ProgrammingRuby/html/tut_classes.html), an [environment](https://mitpress.mit.edu/sicp/full-text/sicp/book/node77.html) (inherited from a [HTTP request](http://tools.ietf.org/html/rfc7231#section-5)). the [environment](https://en.wikipedia.org/wiki/Eval#Ruby) provides a base URI to [resolve relative-URIs](https://tools.ietf.org/html/rfc3986#section-5.2) against

### RDF-compatibility

#### Resource
R is a [subclass](https://encrypted.google.com/search?hl=en&q=inheritance%20ruby) of [RDF::URI](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/URI) and inherits its methods. we add a [bidirectional-mapping](https://en.wikipedia.org/wiki/Bidirectional_map) from [URIs](https://encrypted.google.com/search?hl=en&q=%22URI%20arithmetic%22) to [filesystem names](https://en.wikipedia.org/wiki/Computer_file#Identifying_and_organizing_files)


#### JSON format
a [RDF::Reader](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Reader) interface is defined. there is no [RDF::Writer](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Writer) defined, as one cant [roundtrip](https://en.wikipedia.org/wiki/Round-trip_format_conversion) full RDF. for writing full RDF we recommend [Turtle](http://www.w3.org/TeamSubmission/turtle/)

### Search
[on-line search](https://en.wikipedia.org/wiki/Online_search) is available via [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). no server-side [crawlers](https://en.wikipedia.org/wiki/Web_crawler): you must [GET](ruby/read.rb.html) to trigger indexing of stored [content](https://en.wikipedia.org/wiki/Content_(media))

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
* server can be run elsewhere, link or copy [js/](js/) and [css/](css/) directories to [server-root](.)
* one way to listen on port 80/443 as a non-root user:

``` sh
setcap cap_net_bind_service=+ep $(realpath `which ruby`)
```

## MIRRORS
[src.whats-your.name/pw/](http://src.whats-your.name/pw/)
[gitlab.com/ix/pw](https://gitlab.com/ix/pw)
[repo.or.cz/www](http://repo.or.cz/www)
