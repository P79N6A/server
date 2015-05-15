#watch __FILE__
class R

  ViewGroup[RDFClass] =
    ViewGroup[RDFs+'Datatype'] =
    ViewGroup[Property] =
    ViewGroup[OWL+'Class'] =
    ViewGroup[OWL+'ObjectProperty'] =
    ViewGroup[OWL+'DatatypeProperty'] =
    ViewGroup[OWL+'SymmetricProperty'] =
    ViewGroup[OWL+'TransitiveProperty'] =
    TabularView

  ViewGroup[OWL+'Ontology'] = ViewGroup[BasicResource]

   def R.schemaSources
    table = {}
    open('http://prefix.cc/popular/all.file.txt').each_line{|l|
      unless l.match /^#/
        prefix, uri = l.split(/\t/)
        table[prefix] = uri.chomp
      end}
    table
  end

  # example, import arbitrary doc at prefix (shell):
  #$ R http://schema.org/docs/schema_org_rdfa.html cacheSchema schema
  def cacheSchema prefix
    short = R['schema'].child(prefix).n3
    if !short.e
      puts uri
      head = `curl -L --connect-timeout 6 -I #{uri.sh}`; puts head
      size = head.lines.grep(/^Content-Length/)[-1].do{|l|l.gsub(/\D/,'').to_i}
      unless size && size > 1024e3
        terms = RDF::Graph.load uri
        triples = terms.size
        if triples > 0
          puts "#{triples} triples"
          n3.w terms.dump(:n3)
          n3.ln_s short
        end
      end
    end
  rescue Exception => x
    puts "<#{uri}> #{x}"
  end

  # fetch URI -> doc
  def store options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      if graph.named?
        doc = graph.name.n3
        unless doc.e
          doc.dir.mk
          file = doc.pathPOSIX
          RDF::Writer.open(file){|f|f << graph} ; puts "<#{doc.docroot}> #{graph.count} triples"
          options[:hook][doc,graph,options[:hostname]] if options[:hook]
        end
      end}
    g
  end

  # fetch ALL the schemas prefix.cc identifies
  def R.cacheSchemas
    R.schemaSources.map{|prefix,uri| uri.R.cacheSchema prefix }
  end

end
