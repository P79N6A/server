class R

  def R.schemas
    table = {}
    open('http://prefix.cc/popular/all.file.txt').each_line{|l|
      unless l.match /^#/
        prefix, uri = l.split(/\t/)
        table[prefix] = uri.chomp
      end}
    table
  end

  def R.cacheSchemas
    R.schemas.map{|prefix,uri| uri.R.cacheSchema prefix }
  end

  def cacheSchema prefix
    short = R['schema'].child prefix
    if !short.n3.e
      puts uri
      stat = RDF::Graph.new
      head = `curl --connect-timeout 6 -I #{uri.sh}`; puts head
      stat << RDF::Statement.new(uri.R,R[HTTP+'header'],RDF::Literal(head))
      size = head.lines.grep(/^Content-Length/)[0].do{|l|l.gsub(/\D/,'').to_i}
      unless size && size > 640e3
        terms = RDF::Graph.load uri
        triples = terms.size
        if triples > 0
          puts "#{triples} triples"
          stat << RDF::Statement.new(uri.R,R[VOID+'triples'],RDF::Literal(triples))
          n3.w terms.dump(:n3)
          n3.ln_s short
        end
      end
      short.n3.w stat.dump(:n3)
    end
  rescue Exception => x
    puts "ERROR #{uri} #{x}"
  end

  #  http://gromgull.net/2010/09/btc2010data/predicates.2010.gz

end
