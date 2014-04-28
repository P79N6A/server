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

  def cacheSchema prefix
    graph = RDF::Graph.load uri
    puts graph.size
  end

end
