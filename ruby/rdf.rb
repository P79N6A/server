#watch __FILE__
class E

  def nt;  @nt ||= docBase.a('.nt') end
  def n3;  @n3 ||= docBase.a('.n3') end
  def ttl; @ttl||= docBase.a('.ttl') end

  def E.linkeddata
    @linkeddata ||=
      (begin require 'linkeddata'
       rescue LoadError => e
         puts "linkeddata library not found"
       end)
  end

  def self.renderRDF d,f,e
    E.linkeddata.do{|ld|
    (RDF::Writer.for f).buffer{|w|
      d.triples{|s,p,o|
      if s && p && o
        s = RDF::URI s=='#' ? '' : (s.E.hostURL e)
        p = RDF::URI p
        o = ([E,Hash].member?(o.class) ? (RDF::URI o.E.hostURL(e)) :
             (l = RDF::Literal o
              l.datatype=RDF.XMLLiteral if p == Content
              l)) rescue nil
        (w << (RDF::Statement.new s,p,o) if o ) rescue nil
      end}}}
  end
  
  def triplrRDF format=nil, local=true
    E.linkeddata.do{|ld|
    uri = (local && f) ? d : uri
    RDF::Reader.open(uri, :format => format){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s, [RDF::Node, RDF::URI].member?(o.class) ? E(o) : o.value.do{|v|v.class == String ? v.to_utf8 : v}}}}
  end

  [['application/ld+json',:jsonld],
   ['text/ntriples',:ntriples],
   ['text/turtle',:turtle],
   ['text/n3',:n3]
  ].map{|mime|
    F[Render+mime[0]] = ->d,e{E.renderRDF d, mime[1], e}}

  F['view/data'] = ->d,e {
    local = true
    tab = (local ? '/js/' : 'https://w3.scripts.mit.edu/') + 'tabulator/'
    [(H.css tab + 'tabbedtab'),
     (H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js tab + 'js/mashup/mashlib'),
"<script>
jQuery(document).ready(function() {
    var uri = window.location.href;
    window.document.title = uri;
    var kb = tabulator.kb;
    var subject = kb.sym(uri);
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
});</script>",
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

end
