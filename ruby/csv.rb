#watch __FILE__
class R

  def triplrCSV d
    lines = begin
              CSV.read pathPOSIX
            rescue
              puts "CSV parse-error in #{uri}"
              []
            end

    lines[0].do{|fields| # header-row

      yield uri+'#', Type, R[CSVns+'Table']
      yield uri+'#', CSVns+'rowCount', lines.size

      lines[1..-1].each_with_index{|row,line|
        row.each_with_index{|field,i|
          id = uri + '#row:' + line.to_s
          yield id, fields[i], field
          yield id, Type, R[CSVns+'Row']}}}
  end

  ViewGroup[CSVns+'Row'] = -> g,e {
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    {_: :table, :class => :tab,
     c: [H.css('/css/table'),
         {_: :tr, c: keys.map{|k|
            {_: :th, class: :label, property: k, c: k.R.abbr}}},
         g.resources(e).map{|e|
           {_: :tr, about: e.uri, c: keys.map{|k|
              {_: :td, property: k, c: k=='uri' ? e.R.html : e[k].html}}}}]}}

end
