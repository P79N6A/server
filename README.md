# [pw](http://src.whats-your.name/pw/)

[HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to the [filesystem](http://www.multicians.org/fjcc4.html). one possible use is a [simple](http://suckless.org/philosophy) webserver for [mail](conf/mail/) and [news](conf/news/) ([message/rfc2822](http://www.faqs.org/rfcs/rfc2822.html), [RSS](http://web.resource.org/rss/1.0/spec), [Atom](https://tools.ietf.org/html/rfc4287)). [on-line search](https://en.wikipedia.org/wiki/Online_search) is available via [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). no server-side [crawlers](https://en.wikipedia.org/wiki/Web_crawler): you must [GET](ruby/read.rb.html) to trigger indexing of stored [content](https://en.wikipedia.org/wiki/Content_(media))

## MIMEs

for performance and simplicity of implementation, we use two formats internally: one is a **JSON**-serializable [subset](https://en.wikipedia.org/wiki/Subset) of [RDF](https://ruby-rdf.github.io/) with no [blank-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just [JSON](http://www.json.org/)-native literals. data is arranged for [URI](https://www.ietf.org/rfc/rfc1630.txt) key-lookup and [merger](ruby/JSON.rb.html) into a memory [Hash](http://docs.ruby-lang.org/en/2.0.0/Hash.html)-table, w.o [mapping/expansion/rewriting](http://www.w3.org/TR/json-ld-api/#context-processing-algorithms): [predicate](http://www.w3.org/TR/rdf11-concepts/#dfn-predicate) [URIs](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) are stored in full, no searching inside strings for [base-URI](https://annevankesteren.nl/2005/08/base-examples) prefixes and no [*-LD mapping-frames](http://json-ld.org/spec/latest/json-ld-framing/). also used are **URI-list** files of one [URI per line](http://amundsen.com/hypermedia/urilist/) as primitive [indexes](https://en.wikipedia.org/wiki/Database_index) and [triple](http://stackoverflow.com/questions/273218/whats-an-rdf-triple) building-blocks. the full RDF formats are also available, thanks to Ruby's fantastic RDF library. our **JSON** format has a [RDF::Reader](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Reader) interface. the feed-parsing is also implemented as an **RDF::Reader**. there is no [RDF::Writer](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Writer) as neither format can [roundtrip](https://en.wikipedia.org/wiki/Round-trip_format_conversion) RDF. for writing RDF we recommend using [Turtle](http://www.w3.org/TeamSubmission/turtle/)

## RDF/API
a resource [R](ruby/names.rb.html) can be constructed with R() or R[] syntax or casted from convertible-types (URIs as strings, RDF::URI, Pathname/File handles) by calling method R. it's an [identifier](https://en.wikipedia.org/wiki/Identifier) coupled with an [environment](https://mitpress.mit.edu/sicp/full-text/sicp/book/node77.html) (inherited from a [HTTP request](http://tools.ietf.org/html/rfc7231#section-5)). the [environment](https://en.wikipedia.org/wiki/Eval#Ruby) provides a base URI to [resolve relative-URIs](https://tools.ietf.org/html/rfc3986#section-5.2) against. resource **R** is a [subclass](http://rubylearning.com/satishtalim/ruby_inheritance.html) of [RDF::URI](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/URI) and inherits its methods

## REQUISITES

### on [Debian](http://www.debian.org/)
``` sh
apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config python-pygments
```

### on [Voidlinux](http://www.voidlinux.eu/)
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
* files go in domain/$HOST/path/to/file or path/to/file
* daemon can run elsewhere, link or copy [js/](js/) and [css/](css/) directories to [server-root](.)
* one way to listen on port 80/443 as a non-root user:

``` sh
setcap cap_net_bind_service=+ep $(realpath `which ruby`)
```

## MIRRORS
[src.whats-your.name/pw/](http://src.whats-your.name/pw/) 
[gitlab.com/ix/pw](https://gitlab.com/ix/pw) 
[repo.or.cz/www](http://repo.or.cz/www) 
