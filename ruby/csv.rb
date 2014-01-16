watch __FILE__
class E

  # CSV -> tripleStream
  def triplrCSV d
    d = @r.q['delim']||d
    open(node).readlines.map{|l|l.chomp.split(d) rescue []}.do{|lines|
      lines[0].do{|fields| # ok, we have at least one line..
        yield uri+'#', Type, E[CSV+'Table']
        yield uri+'#', CSV+'rowCount', lines.size
        yield uri+'#', COGS+'View', E[uri+'?view=table']
        lines[1..-1].each_with_index{|row,line|
          row.each_with_index{|field,i|
            id = uri + '#row:' + line.to_s
            yield id, fields[i], field
            yield id, Type, E[CSV+'Row']
          }}}}
  end

  F['view/'+CSV+'Row']=NullView

end
