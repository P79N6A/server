**[pw](http://src.whats-your.name/pw/)** is a [HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to the [filesystem](http://www.multicians.org/fjcc4.html) for [use](http://suckless.org/philosophy) as a web-server for [mail](conf/mail/) and [news](conf/news/) ([message/rfc2822](http://www.faqs.org/rfcs/rfc2822.html), [RSS](http://web.resource.org/rss/1.0/spec), [Atom](https://tools.ietf.org/html/rfc4287)). [on-line search](https://en.wikipedia.org/wiki/Online_search) is available via [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). with no server-side [crawlers](https://en.wikipedia.org/wiki/Web_crawler) one must [GET](ruby/read.rb.html) to trigger indexing of fs [content](https://en.wikipedia.org/wiki/Content_(media)). this is a zero-config (beyond a few symlinks) launch-and-go server which could be seen as a [suckless](http://suckless.org/philosophy) take on a generic filesystem-webserver

## MIMEs

data is converted to a **JSON**-[subset](https://en.wikipedia.org/wiki/Subset) of [RDF](https://ruby-rdf.github.io/) with no [blank-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just [JSON](http://www.json.org/)-native literals, without a [mapping/expansion/rewriting](http://www.w3.org/TR/json-ld-api/#context-processing-algorithms) stage. [predicate](http://www.w3.org/TR/rdf11-concepts/#dfn-predicate) [URIs](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) are stored in full, no searching inside strings for [base-URI](https://annevankesteren.nl/2005/08/base-examples) prefixes and no [mapping-frames](http://json-ld.org/spec/latest/json-ld-framing/). data is structured for [URI](https://www.ietf.org/rfc/rfc1630.txt)-lookup and [merger](ruby/JSON.rb.html) into a memory [Hash](http://docs.ruby-lang.org/en/2.0.0/Hash.html)-table. **URI-list** files have [a URI per line](http://amundsen.com/hypermedia/urilist/) as primitive [indexes](https://en.wikipedia.org/wiki/Database_index) and [triple](http://stackoverflow.com/questions/273218/whats-an-rdf-triple) building-blocks. the simplicity-optimized **JSON** and feed formats have [RDF::Reader](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Reader) interfaces and are merged to a full RDF-model before finally being serialized to the requested response-MIME

## INTERFACES

<table>

<tr><td><b>Resources</b></td><td>
<a href="ruby/names.rb.html">R</a> is constructed or cast from convertible-types (URI|String|JSON-object|File) by calling method R. this is an identifier coupled with an environment (inherited from a <a href="http://tools.ietf.org/html/rfc7231#section-5">HTTP request</a>). the environment provides a base URI to <a href="https://tools.ietf.org/html/rfc3986#section-5.2">resolve relative-URIs</a>. we add a bidirectional name-mapping with filesystem paths. the programmer is encouraged to think in terms of resources, with physical-paths mapped to and from behind the scenes as needed. <strong>R</strong> is a <a href="http://rubylearning.com/satishtalim/ruby_inheritance.html">subclass</a> of <a href="http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/URI">RDF::URI</a> and inherits its methods &mdash; you can send <strong>R</strong> into the <strong>RDF</strong> framework anywhere a <strong>RDF::URI</strong> is expected
</td></tr>

<tr><td style="white-space: nowrap"><b>data-streams</b></td><td>
for streaming triples between functions we use the yield and do{block} features of Ruby to produce and consume a subset of RDF.
argument 0 and 1 are expected to contain a URI in string-form.
argument 2 follows our usual rules for disambiguating a resource (R|RDF::URI|JSON-object) and literal (JSON-value)
</td></tr>

<tr><td style="white-space: nowrap"><b>pages</b></td><td>
there's no one way to break content into pages, in a directory you might want a depth-first or breadth-first traverse or content matching a regular-expression. we provide <a href=ruby/search.fs.rb.html>some ways</a> and hooks to add more
</td></tr>

<tr><td><b>abstracts</b></td><td>
content on a filesystem can be voluminous. summarizers to provide an index to a larger amount of content are <a href=ruby/message.mail.rb.html>defined</a> on RDF-types
</td></tr>

<tr><td><b>HTTP</b></td><td>
a web-server &mdash; launch one with &#39;foreman start&#39;.
a <a href="http://rack.github.io/">Rack</a> interface exposes our <a href="ruby/read.rb.html">handlers</a> to low-level socket-engines like <a href="http://code.macournoyer.com/thin/">Thin</a> and <a href="http://unicorn.bogomips.org/">Unicorn</a> which complete a full web-server
</td></tr>

<tr><td><b>UI</b></td><td>
we serve standard RDF is so you can <a href="https://github.com/solid/solid-apps">bring your own</a> UI. we're not in the business of dictating your user-interface
</td></tr>

<tr><td><b>HTML</b></td><td>
 <a href="http://links.twibright.com/">links</a>/<a href="http://lynx.invisible-island.net/current/">lynx</a>/<a href="http://w3m.sourceforge.net/">w3m</a> (hypertext-browser) capability is important to us so we provide <b>text/html</b> on request. templates are defined on a class (a group of resources) or instance (resource) basis
</td></tr>

</table>

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
