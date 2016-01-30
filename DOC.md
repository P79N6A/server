[HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to a [filesystem](http://www.multicians.org/fjcc4.html) with fast/minimal-dependency RDF-subset metamodel built of Hash and JSON objects. [search](https://en.wikipedia.org/wiki/Online_search) is enabled via [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). domain-specific RDF-type handling on lambda<>URI associations, used to extend server with [mail](conf/mail) and [news](conf/news/NEWS) functionality

## Interface

<table>

<tr><td><b>HTTP</b></td><td>
web-protocol. a <a href="http://rack.github.io/">Rack</a> interface exposes our <a href="ruby/read.rb.html">handlers</a> to low-level socket-engines like <a href="http://code.macournoyer.com/thin/">Thin</a> and <a href="http://unicorn.bogomips.org/">Unicorn</a> which complete a full web-server
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
<b>yield</b> and <b>do</b> keywords denote producing and consuming code, stackable into pipelines <a href=ruby/message.news.rb.html>(feed example)</a>. 
args[0,1] are URI in string form, arg[2] a resource or literal (JSON values)
</td></tr>

<tr><td style="white-space: nowrap"><b>Page</b></td><td>
a page could be a depth or breadth-first traverse of directories, or a narrowing of the default-set matching a regular-expression. we provide <a href=ruby/search.fs.rb.html>some defaults</a> and hooks to add more
</td></tr>

<tr><td><b>Abstract</b></td><td>
content can be voluminous. summarizers are <a href=ruby/message.mail.rb.html>definable</a> on RDF-types
</td></tr>

<tr><td><b>future</b></td><td>
planned: RDFization via virtual-turtle (for third-party LDP daemons) on a FUSE interface and a Ruby (RDF::Repository) interface. this would allow mixing our functionality into other web-servers in additional ways beyond URI-path routing or Rack's interface. <a href=https://github.com/solid>Solid</a> apps require fairly-specific server-side behavior and we could free ourselves from having to constantly tweak our server to match it. it's also good to have more compatible implementations in different languages, and we offer things that will never be in solid-spec, so this server isn't going away either. or both, ldnode in front for ACL-checks and Turtle-service with non-RDF falling through to us - over HTTP, as FUSE requires a kernel-module which limits its installability and adds a slightly-exotic dependency. also planned is a port of the email and Atom/RSS-feed RDFizer to JS, an addon to ldnode to bring it summarization (server-side reduction), pagination, and HTML-view features, and a port of the entire server, except with Irmin instead of VFS, to OCaml for deployment as a mirageOS unikernel - likely by adding Solid/LDP-features to their HTTP daemon rather than starting from scratch. if any of this sounds like stuff you want you could of course <a href=http://mw.logbook.am/carmen/>contact me</a> and sponsor it, otherwise i'll do what i feel like which may include nothing as this server's already perfectly adequate for my needs
</td></tr>

</table>

## MIMEs

our **JSON** format omits [unidentified-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) and [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes) - if you want blank-nodes or can't express within [JSON](http://www.json.org/)-literals, full Turtle is also supported. indexes are actually **URI-list** files of [one URI per line](http://amundsen.com/hypermedia/urilist/). data expands to a full RDF-model if requested in **Accept**, otherwise stays in our accelerated subset through to serialization. if you are fully-futuristic and use only RDF, check out [ldnode](https://github.com/linkeddata/ldnode)