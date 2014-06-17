#watch __FILE__
class R

  def triplrCSV d
    d = @r.q['delim']||d
    CSV.read(pathPOSIX).do{|lines|
      lines[0].do{|fields| # ok, we have at least one line..
        yield uri+'#', Type, R[CSVns+'Table']
        yield uri+'#', CSVns+'rowCount', lines.size
        yield uri+'#', COGS+'View', R[uri+'?view=csv']
        lines[1..-1].each_with_index{|row,line|
          row.each_with_index{|field,i|
            id = uri + '#row:' + line.to_s
            yield id, fields[i], field
            yield id, Type, R[CSVns+'Row']
          }}}}
  end

  View['csv'] = -> d,e {
    d.delete_if{|s,r|
      !(r.class==Hash &&
        r[Type].do{|t|
          t.class == Array &&
          t.map(&:maybeURI).member?(CSVns+'Row')})}
    View['table'][d,e]}

  View[CSVns+'Row'] = -> d,e {}

end
