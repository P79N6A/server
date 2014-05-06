watch __FILE__
class R

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

  GET['/schema'] = -> e,r {
    graph = RDF::Graph.new
    name = e.path.sub(/^\/schema/,'').tail || ''
    res = R['/schema/' + name]
    if !name.empty? && res.n3.e
      r.q['view'] ||= 'tabulate'
      res.setEnv(r).response
    elsif name.empty?
      R.schemas.sort.map{|s| graph << RDF::Statement.new(R['#'], R[LDP+'contains'], s.R.stripDoc)}
      r.graphResponse graph
    else
      s = R.groonga.select{|r|(r['graph'] == 'schema') & r.match(name){|f|(f.uri * 6)|f.content}}
      s = s.sort([{:key => "_score", :order => "descending"}], :limit => 255)
      if r.format == 'text/html' && !r.q.has_key?('rdfa')
        m = Hash[s.map{|r|[r['.uri'], JSON.parse(r['content'])]}]
        [200,{'Content-Type'=> 'text/html'},[Render[r.format][m, r]]]
      else
        s.map{|r| R.resourceToGraph (JSON.parse r['content']), graph }
        r.graphResponse graph
      end
    end}

  def R.cacheSchemas
    R.schemaSources.map{|prefix,uri| uri.R.cacheSchema prefix }
  end

  def cacheSchema prefix
    short = R['schema'].child(prefix).n3
    if !short.e
      puts uri
      head = `curl -L --connect-timeout 6 -I #{uri.sh}`; puts head
      size = head.lines.grep(/^Content-Length/)[-1].do{|l|l.gsub(/\D/,'').to_i}
      unless size && size > 720e3
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
    puts "ERROR #{uri} #{x}"
  end

  def R.indexSchemas
    R.schemas.map{|s| s.roonga 'schema'; puts s } # keyword index
    nil
  end

end
