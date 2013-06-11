class E

  # CSV -> tripleSource
  def triplrCSV d
    d = @r.q['delim']||d
    open(node).readlines.map{|l|l.chomp.split(d) rescue []}.do{|t|
      t[0].do{|x|
        t[1..-1].each_with_index{|r,ow|r.each_with_index{|v,i|
            yield uri+'#r'+ow.to_s,x[i],v
          }}}}
  end

end
