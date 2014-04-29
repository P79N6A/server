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
    puts "cacheSchema <#{uri}>"
    short = R['schema'].child prefix
    if !short.e
      terms = RDF::Graph.load uri
      stats = RDF::Graph.new
      size = terms.size
      if size > 0
        puts "<#{uri}> #{size} triples"
        n3.w terms.dump(:n3)
        n3.ln_s 
      end
      
    end
  rescue Exception => x
    puts "ERROR #{uri} #{x}"
  end

  #  http://gromgull.net/2010/09/btc2010data/predicates.2010.gz

end
