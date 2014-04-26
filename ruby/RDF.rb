#watch __FILE__
class R

  def self.renderRDF d,f,e
    (RDF::Writer.for f).buffer{|w|
      d.triples{|s,p,o|
      if s && p && o
        s = RDF::URI s == '#' ? e['REQUEST_URI'] : s
        p = RDF::URI p
        o = ([R,Hash].member?(o.class) ? (RDF::URI o.uri) :
             (l = RDF::Literal o
              l.datatype=RDF.XMLLiteral if p == Content
              l)) rescue nil
        (w << (RDF::Statement.new s,p,o) if o ) rescue nil
      end}}
  end
  
  [['application/ld+json',:jsonld],
   ['application/rdf+xml',:rdfxml],
   ['text/ntriples',:ntriples],
   ['text/turtle',:turtle],
   ['text/n3',:n3]
  ].map{|mime|
    Render[mime[0]] = ->d,e{R.renderRDF d, mime[1], e}}

  def addDocsRDF options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dir.mk
          RDF::Writer.open(doc.d){|f|f << graph} ; puts "<#{doc.docroot}> #{graph.count} triples"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end

  def rdfDoc pass = %w{atom e jsonld n3 nt owl rdf ttl} # narrow doc-types to those readable by RDF::Reader
    doc = self
    unless pass.member? ext # already an RDF doc
      doc = R['/cache/RDF/' + (R.dive uri.h) + '.e']
      unless doc.e && doc.m > m # up-to-date?
        g = {} # doc graph
        [:triplrMIME,:triplrInode].map{|t| fromStream g, t} # triplize
        doc.w g, true # write doc
      end
    end
    doc
  end

  Tabulate = -> d,e { e.q['view'] ||= 'tabulate' ; nil }
  View['tabulate'] = ->d,e { src = 'https://w3.scripts.mit.edu/tabulator/'
    [(H.css src + 'tabbedtab'),(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),(H.js src + 'js/mashup/mashlib'),
"<script>jQuery(document).ready(function() {
    var uri = window.location.href;
    window.document.title = uri;
    var kb = tabulator.kb;
    var subject = kb.sym(uri);
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
});</script>",
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  def triplrN3
    RDF::Reader.open(d, :format => :n3, :base_uri => stripDoc){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s,[RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}}
  end

  def n3; docroot.a '.n3' end

end
