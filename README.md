# [pw](http://src.whats-your.name/pw/)

[HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to the [filesystem](http://www.multicians.org/fjcc4.html). one possible [use](http://suckless.org/philosophy) is a webserver for [mail](conf/mail/) and [news](conf/news/) ([message/rfc2822](http://www.faqs.org/rfcs/rfc2822.html), [RSS](http://web.resource.org/rss/1.0/spec), [Atom](https://tools.ietf.org/html/rfc4287)). [on-line search](https://en.wikipedia.org/wiki/Online_search) is available via [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). no server-side [crawlers](https://en.wikipedia.org/wiki/Web_crawler): you must [GET](ruby/read.rb.html) to trigger indexing of stored [content](https://en.wikipedia.org/wiki/Content_(media))

## MIMEs

for performance and simplicity, we use two formats. a **JSON**-storable [subset](https://en.wikipedia.org/wiki/Subset) of [RDF](https://ruby-rdf.github.io/) with no [blank-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just [JSON](http://www.json.org/)-native literals, without a [mapping/expansion/rewriting](http://www.w3.org/TR/json-ld-api/#context-processing-algorithms) stage. [predicate](http://www.w3.org/TR/rdf11-concepts/#dfn-predicate) [URIs](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) are stored in full, no searching inside strings for [base-URI](https://annevankesteren.nl/2005/08/base-examples) prefixes and no [*-LD mapping-frames](http://json-ld.org/spec/latest/json-ld-framing/). data is structured for fast (standard-library, often C/JAVA-accelerated) parsing and [URI](https://www.ietf.org/rfc/rfc1630.txt) key-lookup and [merger](ruby/JSON.rb.html) into a memory [Hash](http://docs.ruby-lang.org/en/2.0.0/Hash.html)-table. also used are **URI-list** files with [URI per line](http://amundsen.com/hypermedia/urilist/) as primitive [indexes](https://en.wikipedia.org/wiki/Database_index) and [triple](http://stackoverflow.com/questions/273218/whats-an-rdf-triple) building-blocks. the full RDF formats are also available, thanks to Ruby's fantastic RDF library. for merger of our optimized-subset into full-RDF requests, **JSON**-format has a [RDF::Reader](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Reader) interface. the feed-parsing is also implemented as an **RDF::Reader**. there is no [RDF::Writer](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Writer) as neither format can [roundtrip](https://en.wikipedia.org/wiki/Round-trip_format_conversion) RDF. for writing RDF we recommend using [Turtle](http://www.w3.org/TeamSubmission/turtle/)

## INTERFACES

#### Resource - the key building-block
resource [R](ruby/names.rb.html) is constructed with R() or R[] or cast from convertible-types (URI as String, URI as JSON-object, RDF::URI, File-handle) by instance-method 'R'. our resource reference is an identifier coupled with an [environment](https://mitpress.mit.edu/sicp/full-text/sicp/book/node77.html) (inherited from a [HTTP request](http://tools.ietf.org/html/rfc7231#section-5)). the [environment](https://en.wikipedia.org/wiki/Eval#Ruby) provides a base URI to [resolve relative-URIs](https://tools.ietf.org/html/rfc3986#section-5.2) against. we use syntactical-conventions in URI-expressions for a bidirectional name-mapping with filesystem paths. the programmer is encouraged to think in terms of resources, with physical-paths mapped to and from behind the scenes as needed. **R** is a [subclass](http://rubylearning.com/satishtalim/ruby_inheritance.html) of [RDF::URI](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/URI) and inherits its methods. you can send **R** into the **RDF** framework anywhere a **RDF::URI** is expected

#### streaming RDF
for streaming triples between functions we use the built-in yield and do {block} features of Ruby to produce and consume our subset of RDF.
argument 0 and 1 are expected to be a string-type containing a URI.
argument 2 follows our usual rules for disambiguating a resource (RDF::URI / R / JSON-object with uri-key) and literal (JSON value)

#### HTTP
a **HTTP** interface is available as a web-server. launch one with 'foreman start'.
a [Rack](http://rack.github.io/) interface is available and used to expose our [handlers](ruby/read.rb.html) to low-level socket-handling engines like [Thin](http://code.macournoyer.com/thin/) and [Unicorn](http://unicorn.bogomips.org/) which comprise the lower-layers of the web-server. they call our HTTP-method (unimaginatively called ['call'](ruby/HTTP.rb.html), as Rack-interface specifies) on a resource instance which will dispatch the appropriate HTTP method.

#### LDP
our server is generally [LDP-compatible](http://www.w3.org/TR/ldp/), although once-again there were certain parts we thought were too complicated like the plethora of container-types. nonetheless, since Ruby now has an [LDP](https://github.com/solid/solid-spec/issues/38) library, unless we drop dead or lose interest first we will probably write a [RDF::Repository](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Repository) interface so our store can claim a fully-compliant [LDP interface](https://github.com/ruby-rdf/rdf-ldp)

## History
modus-operandi of this project has generally been: can we shave off bits of RDF's featureset and make it much less complicated to implement by gaining trivial mappings to filesystem paths (instead of LDP's 4~ types of containers we just have one: the filesystem just has directories), JSON-objects (a compiled-C blob in Ruby's stdlib is always going to trounce pure-ruby parsers that have to take all of Turtle's footnotes into account), the Hash library's iteration/manipulation functions (a flexible memory-model class? Hash with URI-keys will do). originally Ruby didn't have an RDF library and there was only one [author](mailto:carmen@whats-your.name) with only so much time who wanted something like an LDP daemon, these decisions persisted because performance (we want to generate a heatmap from a few months of mails without an offline stats pass. since JSON parsing is superoptimized we'll just scan a few thousand files at request-time). we want you to be able to use either the simple almost-RDF tricks or go whole-hog, which is where the above interfaces come into play. as hardware becomes faster, i might go whole-hog, so there's no reason to "release" this as everything's in flux - "install" is just a symlink to the live-source path

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
