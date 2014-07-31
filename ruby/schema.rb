#watch __FILE__
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
    name = r.q['q'] || e.path.sub(/^\/schema/,'').tail || ''
    if name.empty?
      schemas = R.schemas.sort.map{|s|s.R.stripDoc}
      if r.format == 'text/html'
        m = {'#s' => {Type => R['#schemas']}, '#' => {LDP+'contains' => schemas}}
        r.htmlResponse m
      else
        schemas.map{|s| graph << RDF::Statement.new(R['#'], R[LDP+'contains'], s)}
        r.graphResponse graph        
      end
    else # search
      s = R.groonga.select{|r|(r['graph'] == 'schema') & r.match(name.gsub /\W+/,' '){|f|(f.uri * 6)|f.content}}
      s = s.sort([{:key => "_score", :order => "descending"}], :limit => 255)
      if r.format == 'text/html' && !r.q.has_key?('rdfa')
        m = {'#s' => {Type => R['#schemas']}}
        s.map{|r| m[r['.uri']] = (JSON.parse r['content'])}
        r.htmlResponse m
      else
        s.map{|r| R.resourceToGraph (JSON.parse r['content']), graph }
        r.graphResponse graph
      end
    end}

  View['#schemas'] = -> d,e {
    [{_: :form, action: '/schema', c: {_: :input, name: :q, style: 'font-size:2em'}},(H.js '/js/search')]}

  def R.cacheSchemas
    R.schemaSources.map{|prefix,uri| uri.R.cacheSchema prefix }
  end

  # usage (sh)
  # R http://schema.org/docs/schema_org_rdfa.html cacheSchema schema
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
    puts "ERROR #{uri} #{x}"
  end

  def R.indexSchemas
    R.schemas.map{|s| s.roonga 'schema'; puts s } # keyword index
    nil
  end

end
