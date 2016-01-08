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
we love interfaces which enable modularity and reuse, but prefer to not invent new ones. one possibility is offering our RDF-conversion service in Turtle to other daemons like <a href=https://github.com/linkeddata/ldnode>ldnode</a>/<a href=https://github.com/linkeddata/gold>gold</a> on a FUSE filesystem. this server may be disappear as an actively-maintained project as functionality is factored out and replaced with an even-more-generic SoLiD/LDP server
</td></tr>

</table>

