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
      res.setEnv(r).response
    elsif name.empty?
      R.schemas.sort.map{|s| graph << RDF::Statement.new(R['#'], R[LDP+'contains'], s.R.stripDoc)}
      r.graphResponse graph
    else
      

      R.groonga.select{|r|
        (r['graph'] == 'schema') & r.match(q){|f|(f.uri * 6)|f.content}}.
        map{|r|puts [r.key.key,r.score].join ' '}
      nil
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
    R.schemas.map{|s| s.roonga 'schema' }
    nil
  end

end
