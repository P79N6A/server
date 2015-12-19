**[pw](http://src.whats-your.name/pw/)** is a [HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to the [filesystem](http://www.multicians.org/fjcc4.html) for [use](http://suckless.org/philosophy) as a web-server for [mail](conf/mail/) and [news](conf/news/) ([message/rfc2822](http://www.faqs.org/rfcs/rfc2822.html), [RSS](http://web.resource.org/rss/1.0/spec), [Atom](https://tools.ietf.org/html/rfc4287)). [on-line search](https://en.wikipedia.org/wiki/Online_search) is available via [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). with no server-side [crawlers](https://en.wikipedia.org/wiki/Web_crawler) one must [GET](ruby/read.rb.html) to trigger indexing of fs [content](https://en.wikipedia.org/wiki/Content_(media)). this is a zero-config launch-and-use server which could be seen as a [suckless](http://suckless.org/philosophy) take on a generic fs-backed webserver

## MIMEs

in the internal cache a **JSON** subset of [RDF](https://ruby-rdf.github.io/) is used. for [simplicity](http://www.w3.org/TR/json-ld-api/#context-processing-algorithms) this means no [blank-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just [JSON](http://www.json.org/)-native literals. indexes are built in **URI-list** files of [one URI per line](http://amundsen.com/hypermedia/urilist/). the **JSON** and Atom/RSS feed formats have [RDF::Reader](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Reader) interfaces and expand to a full RDF-model if requested, otherwise data stays in our optimized subset through to serialization.

## INTERFACES

<table>

<tr><td><b>resources</b></td><td>
<a href="ruby/names.rb.html">R</a> is constructed or cast from convertible-types (URI-string|JSON-object|File) by calling method R. it is an identifier coupled with an environment (inherited from a <a href="http://tools.ietf.org/html/rfc7231#section-5">HTTP request</a>). the environment provides a base URI to <a href="https://tools.ietf.org/html/rfc3986#section-5.2">resolve relative-URIs</a>. a bidirectional name-mapping with filesystem paths is used to map storage locations. <strong>R</strong> is a <a href="http://rubylearning.com/satishtalim/ruby_inheritance.html">subclass</a> of <a href="http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/URI">RDF::URI</a> and is usable anywhere a <strong>RDF::URI</strong> is allowed
</td></tr>

<tr><td style="white-space: nowrap"><b>data-streams</b></td><td>
for streaming triples between functions, <b>yield</b> and <b>do</b> keywords denote producing and consuming code.
indexes 0,1 contain a URI in string arguments, index 2 a resource (R|RDF::URI) or literal (JSON-value)
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
we serve standard RDF so you can <a href="https://github.com/solid/solid-apps">bring your own</a> UI. we're not in the business of dictating your user-interface
</td></tr>

<tr><td><b>HTML</b></td><td>
 <a href="http://links.twibright.com/">links</a>/<a href="http://lynx.invisible-island.net/current/">lynx</a>/<a href="http://w3m.sourceforge.net/">w3m</a> (hypertext-browser) capability is important to us so we provide <b>text/html</b> on request. templates are defined on a class (a group of resources) or instance (resource) basis
</td></tr>

<tr><td><b>future</b></td><td>
we love interfaces, but prefer to not invent new ones. one possibility is offering our automated RDF-conversion in virtual Turtle-files to other daemons like <a href=https://github.com/linkeddata/ldnode>ldnode</a>/<a href=https://github.com/linkeddata/gold>gold</a> on a FUSE filesystem.
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
