watch __FILE__
class R

  ViewGroup[RDFClass] =  ViewGroup[OWL+'Class'] = -> g,e {
    ['<br>',{_: :b, style: "font-size:1.6em", c: 'Class'}, ViewGroup[CSVns+'Row'][g,e]]}

  ViewGroup[Property] = -> g,e {
    ['<br>',{_: :b, style: "font-size:1.3em", c: 'Properties'}, ViewGroup[CSVns+'Row'][g,e]]}

  ViewGroup[RDFs+'Datatype'] = -> g,e {
    ['<br>',{_: :b, style: "font-size:1.3em", c: 'Datatypes'}, ViewGroup[CSVns+'Row'][g,e]]}

  ViewGroup[OWL+'Ontology'] = ViewGroup[Resource]

   def R.schemaSources
    table = {}
    open('http://prefix.cc/popular/all.file.txt').each_line{|l|
      unless l.match /^#/
        prefix, uri = l.split(/\t/)
        table[prefix] = uri.chomp
      end}
    table
  end

  def R.schemas
    R['schema'].c.select{|f|f.node.symlink?}
  end

  # $ R http://schema.org/docs/schema_org_rdfa.html cacheSchema schema
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


  def R.cacheSchemas
    R.schemaSources.map{|prefix,uri| uri.R.cacheSchema prefix }
  end

  def R.indexSchemas
    R.schemas.map{|s| s.roonga 'schema'; puts s } # keyword index
    nil
  end

end
