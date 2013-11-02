#watch __FILE__
class E

  def self.renderRDF d,f
    require 'linkeddata'
    (RDF::Writer.for f).buffer{|w|
      d.values.each{|r| r.triples{|s,p,o|
          s = RDF::URI s
          p = RDF::URI p
          o = begin
                [E,Hash].member?(o.class) ? (RDF::URI o.uri) : (RDF::Literal o)
              rescue Exception => e
                puts "#{e} \ntriple:\n#{s} #{p} #{o}"
              end
            w << (RDF::Statement.new s,p,o) if o }}}
  end

  def triplrRDF f
    require 'linkeddata'
    RDF::Reader.open(d, :format => f){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s, [RDF::Node, RDF::URI].member?(o.class) ? E(o) : o.value.do{|v|v.class == String ? v.to_utf8 : v}}}
  end

  [['application/ld+json',:jsonld],
   ['application/rdf+xml',:rdfxml],
   ['text/ntriples',:ntriples],
   ['text/turtle',:turtle],
   ['text/rdf+n3',:n3],
   ['text/n3',:n3]
  ].map{|mime|
    F[Render+mime[0]] = ->d,a=nil{E.renderRDF d, mime[1]}}

end
