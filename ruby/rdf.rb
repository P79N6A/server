#watch __FILE__
class E

  begin require 'linkeddata'; rescue LoadError => e; puts 'linkeddata library 404' end

  def self.renderRDF d,f
    (RDF::Writer.for f).buffer{|w|
      d.triples{|s,p,o|
        s = RDF::URI s.E.url
        p = RDF::URI p
        o = ([E,Hash].member?(o.class) ? (RDF::URI o.url) : (RDF::Literal o)) rescue nil
        (w << (RDF::Statement.new s,p,o) if o ) rescue nil
      }}
  end
  
  def triplrRDF format=nil, local=true
    uri = (local && f) ? d : uri
    RDF::Reader.open(uri, :format => format){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s, [RDF::Node, RDF::URI].member?(o.class) ? E(o) : o.value.do{|v|v.class == String ? v.to_utf8 : v}}}
  end

  [['application/ld+json',:jsonld],
   ['application/json+ld',:jsonld],
   ['application/jsonld',:jsonld],
   ['application/rdf+xml',:rdfxml],
   ['application/rdfxml',:rdfxml],
   ['text/ntriples',:ntriples],
   ['text/turtle',:turtle],
   ['text/rdf+n3',:n3],
   ['text/n3',:n3]
  ].map{|mime|
    F[Render+mime[0]] = ->d,a=nil{E.renderRDF d, mime[1]}}

end
