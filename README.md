a webserver

## Install
``` sh
                                       # install non-ruby dependencies
apt-get install ruby bundler libssl-dev libxml2-dev libxslt1-dev pkg-config source-highlight python-pygments # Debian
xbps-install base-devel ruby ruby-devel libxml2-devel libxslt-devel source-highlight python-Pygments && gem install bundler # voidlinux

git clone https://gitlab.com/ix/pw.git # get source

cd pw/ruby                             # goto source-directory
bundle install                         # install ruby dependencies
ruby install                           # install this package
```

* files go in domain/$HOSTNAME/path/to/file or path/to/file
* link or copy [js/](js/) and [css/](css/) to [server-root](.)

## RUN
``` sh
unicorn -rww -o 127.0.0.1 -p 80 --no-default-middleware # Unicorn, on localhost
thin -rww --threaded -p 80 -a 127.0.0.1 start # thin
```

## Interfaces

<table>

<tr><td><b>MIME</b></td><td>
our native <strong>JSON</strong> format omits <a href="http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/">unidentified-nodes</a> and <a href="http://www.w3.org/TR/turtle/#turtle-literals">special-syntax</a> <a href="http://www.w3.org/TR/rdf11-concepts/#section-Datatypes">literal-datatypes/languages</a> - if you want blank-nodes or can&#39;t express within <a href="http://www.json.org/">JSON</a>-literals, <a href="https://www.w3.org/TR/turtle/">Turtle</a> is also supported. indexes are implemented with <strong>URI-list</strong> files of <a href="http://amundsen.com/hypermedia/urilist/">one URI per line</a>. data expands to a full RDF-model if requested in <strong>Accept</strong>, otherwise stays in our accelerated subset through to serialization. if you don't need Non-RDF MIME translations, check out <a href="https://github.com/solid/node-solid-server">node-solid</a>
</td></tr>

<tr><td><b>HTTP</b></td><td>
web-protocol. a <a href="http://rack.github.io/">Rack</a> interface exposes our <a href="ruby/HTTP.rb.html">handlers</a> to low-level socket-engines like <a href="http://code.macournoyer.com/thin/">Thin</a> and <a href="http://unicorn.bogomips.org/">Unicorn</a> which complete a full web-server
</td></tr>

<tr><td><b>UI</b></td><td>
we serve standard RDF so you can <a href="https://github.com/solid/solid-apps">bring your own</a> UI. we're not in the business of dictating your user-interface but do provide a default which is Javascript-free
</td></tr>

<tr><td><b>HTML</b></td><td>
 <a href="http://links.twibright.com/">links</a>/<a href="http://lynx.invisible-island.net/current/">lynx</a>/<a href="http://w3m.sourceforge.net/">w3m</a> compatibility is important to us so we provide <b>text/html</b> on request. renderers are associated to RDF-types
</td></tr>

<tr><td><b>Resource</b></td><td>
<a href="ruby/names.rb.html">R</a> is constructed or cast from convertible-types (URI-string, JSON-object, File) by calling method R. it's an identifier coupled with an environment (inherited from a <a href="http://tools.ietf.org/html/rfc7231#section-5">HTTP request</a>). the environment affixes a base to <a href="https://tools.ietf.org/html/rfc3986#section-5.2">resolve relative-URIs</a>. a bidirectional name-mapping with filesystem paths is used to map storage locations. <strong>R</strong> is a <a href="http://rubylearning.com/satishtalim/ruby_inheritance.html">subclass</a> of <a href="http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/URI">RDF::URI</a> and is usable anywhere a <strong>RDF::URI</strong> is allowed
</td></tr>

<tr><td style="white-space: nowrap"><b>Triple</b></td><td>
<b>yield</b> and <b>do</b> keywords denote producing and consuming code, stackable into pipelines <a href=ruby/message.rb.html>(feed example)</a>. 
args[0,1] are URI strings, arg[2] a resource or literal (JSON value)
</td></tr>

<tr><td style="white-space: nowrap"><b>Page</b></td><td>
a page could be a depth or breadth-first traverse of directories, or a narrowing of the default-set matching a regular-expression. we provide <a href=ruby/search.rb.html>some defaults</a> and hooks to add more
</td></tr>

<tr><td><b>Abstract</b></td><td>
content can be voluminous. summarizers can be defined per RDF-type
</td></tr>

</table>

## Mirrors

[src.whats-your.name/pw/](http://src.whats-your.name/pw/)
[gitlab.com/ix/pw](https://gitlab.com/ix/pw)
[repo.or.cz/www](http://repo.or.cz/www)
