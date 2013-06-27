class E

  fn Render+'text/rdf+n3',  ->d,_=nil{E.renderRDF d,:n3}
  fn Render+'text/ntriples',->d,_=nil{E.renderRDF d,:ntriples}
  fn Render+'text/turtle',  ->d,_=nil{E.renderRDF d,:turtle}
  fn Render+'application/ld+json',->d,_=nil{E.renderRDF d,:jsonld}
  fn Render+'application/rdf+xml',->d,_=nil{E.renderRDF d,:rdfxml}

  def self.requireRDF; %w{n3 rdfa rdfxml turtle}.map{|r|require 'rdf/'+r}; require 'json/ld' end

  def self.renderRDF d,f=:ntriples; E.requireRDF
    RDF::Writer.for(f).buffer{|w|
      d.values.each{|r|
        r.triples{|s,p,o|
          w << RDF::Statement.new(RDF::URI(s),
                                  RDF::URI(p),
                                  (o.class==Hash||o.class==E) ?
                                  RDF::URI(o.uri) :
                                  RDF::Literal(o))}}}
  rescue Exception => e
  end

  def triplrRDFformats t=nil
    E.requireRDF
    (t == :rdfa ? RDF::RDFa : RDF)::Reader.
      open(e ? readlink.d : uri, :format => t){|r|
      r.each_triple{|s,p,o|
#        puts [s.class,s, p.class,p, o.class,o].join(' ')
        yield s.to_s, p.to_s,
        ((o.class==RDF::Node || o.class==RDF::URI) ? o.to_s.E :
                                                     o.value.do{|v|
                                                       v.class == String ? v.to_utf8 : v})
      }}; self
  rescue Exception => e
  end
  
  def cacheTurtle; docBase.a('.ttl').do{|t| t.e || t.w(`rapper -o turtle #{uri}`) ; t } end

  def appendNT g
    docBase.a('.nt').no.open('a').do{|n|
      n.write E.renderRDF g
      n.flush } end

end
