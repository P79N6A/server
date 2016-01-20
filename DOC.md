[HTTP](https://www.mnot.net/blog/2014/06/07/rfc2616_is_dead) interface to a [filesystem](http://www.multicians.org/fjcc4.html) with a simple/fast/low-dependency subset of RDF as the default metadata-model, implemented using Ruby's built-in Hash and JSON class. [search](https://en.wikipedia.org/wiki/Online_search) is enabled with [Groonga](http://groonga.org/) and [grep](http://www.gnu.org/software/grep/manual/grep.html). domain-specific handling for RDF-types by associating lambdas with URIs. [author](http://mw.logbook.am/carmen/)

## Interface

<table>

<tr><td><b>resources</b></td><td>
<a href="ruby/names.rb.html">R</a> is constructed or cast from convertible-types (URI-string|JSON-object|File) by calling method R. it's an identifier coupled with an environment (inherited from a <a href="http://tools.ietf.org/html/rfc7231#section-5">HTTP request</a>). the environment provides a base URI to <a href="https://tools.ietf.org/html/rfc3986#section-5.2">resolve relative-URIs</a>. a bidirectional name-mapping with filesystem paths is used to map storage locations. <strong>R</strong> is a <a href="http://rubylearning.com/satishtalim/ruby_inheritance.html">subclass</a> of <a href="http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/URI">RDF::URI</a> and is usable anywhere a <strong>RDF::URI</strong> is allowed
</td></tr>

<tr><td style="white-space: nowrap"><b>data-streams</b></td><td>
for streaming triples between functions, <b>yield</b> and <b>do</b> keywords denote producing and consuming code.
indexes 0,1 are URI in string arguments, index 2 a resource (R|RDF::URI) or literal (JSON-value)
</td></tr>

<tr><td style="white-space: nowrap"><b>pages</b></td><td>
how will you break content into pages? a depth-first or breadth-first traverse of directories, a narrowing of the default-set matching a regular-expression.. we provide <a href=ruby/search.fs.rb.html>some ideas</a> and hooks to add more
</td></tr>

<tr><td><b>abstracts</b></td><td>
content on a filesystem can be voluminous. summarizers to index a larger amount of content are <a href=ruby/message.mail.rb.html>defined</a> on RDF-types
</td></tr>

<tr><td><b>HTTP</b></td><td>
a web-server &mdash; launch one with &#39;foreman start&#39;.
a <a href="http://rack.github.io/">Rack</a> interface exposes our <a href="ruby/read.rb.html">handlers</a> to low-level socket-engines like <a href="http://code.macournoyer.com/thin/">Thin</a> and <a href="http://unicorn.bogomips.org/">Unicorn</a> which complete a full web-server
</td></tr>

<tr><td><b>UI</b></td><td>
we serve standard RDF so you can <a href="https://github.com/solid/solid-apps">bring your own</a> UI. we're not in the business of dictating your user-interface but provide a default which is Javascript-free (<a href=http://d3js.org/>D3-vis</a> aside)
</td></tr>

<tr><td><b>HTML</b></td><td>
 <a href="http://links.twibright.com/">links</a>/<a href="http://lynx.invisible-island.net/current/">lynx</a>/<a href="http://w3m.sourceforge.net/">w3m</a> compatibility is important to us so we provide <b>text/html</b> on request. rendering is defined on a class (group of resources) or instance (resource) basis
</td></tr>

<tr><td><b>future</b></td><td>
we love interfaces which enable modularity and reuse. one plan is offering our RDF-ification as virtual-Turtle to daemons like <a href=https://github.com/linkeddata/ldnode>ldnode</a>/<a href=https://github.com/linkeddata/gold>gold</a> over a FUSE interface</td></tr>

</table>

## MIMEs

in our cache a **JSON** subset of [RDF](https://ruby-rdf.github.io/) is used. for [simplicity](http://www.w3.org/TR/json-ld-api/#context-processing-algorithms) this means no [unidentified-nodes](http://milicicvuk.com/blog/2011/07/14/problems-of-the-rdf-model-blank-nodes/) or [special-syntax](http://www.w3.org/TR/turtle/#turtle-literals) [literal-datatypes/languages](http://www.w3.org/TR/rdf11-concepts/#section-Datatypes), just [JSON](http://www.json.org/)-native literals. indexes consist of **URI-list** files with [one URI per line](http://amundsen.com/hypermedia/urilist/). internal **JSON** and non-RDF formats have [RDF::Reader](http://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Reader) interfaces and expand to a full RDF-model if requested, otherwise data stays in our optimized subset through to serialization.

