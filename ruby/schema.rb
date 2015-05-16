class R

  ViewGroup[RDFClass] =
    ViewGroup[RDFs+'Datatype'] =
    ViewGroup[Property] =
    ViewGroup[OWL+'Class'] =
    ViewGroup[OWL+'Ontology'] =
    ViewGroup[OWL+'ObjectProperty'] =
    ViewGroup[OWL+'DatatypeProperty'] =
    ViewGroup[OWL+'SymmetricProperty'] =
    ViewGroup[OWL+'TransitiveProperty'] =
    TabularView

   def R.schemas # list schemas
    table = {}
    open('http://prefix.cc/popular/all.file.txt').each_line{|l|
      unless l.match /^#/ # skip
        prefix, uri = l.split(/\t/)
        table[prefix] = uri.chomp
      end}
    table
   end

   def R.cacheSchemas # cache all the schemas
     R.schemas.map{|prefix,uri| uri.R.cacheSchema prefix }
   end

   # Ruby: R('http://schema.org/docs/schema_org_rdfa.html').cacheSchema 'schema'
   # sh: R http://schema.org/docs/schema_org_rdfa.html cacheSchema schema
   def cacheSchema prefix
    short = R['schema'].child(prefix).n3
    if !short.e # already fetched, unlink shortcut to uncache
      terms = RDF::Graph.load uri
      triples = terms.size
      if triples > 0
        puts "#{uri} :: #{triples} triples"
        n3.w terms.dump :n3
        n3.ln_s short
      end
    end
   end

end
