#watch __FILE__
class R

  # CSV -> tripleStream
  def triplrCSV d
    d = @r.q['delim']||d
    open(node).readlines.map{|l|l.chomp.split(d) rescue []}.do{|lines|
      lines[0].do{|fields| # ok, we have at least one line..
        yield uri+'#', Type, R[CSV+'Table']
        yield uri+'#', CSV+'rowCount', lines.size
        yield uri+'#', COGS+'View', R[uri+'?view=csv']
        lines[1..-1].each_with_index{|row,line|
          row.each_with_index{|field,i|
            id = uri + '#row:' + line.to_s
            yield id, fields[i], field
            yield id, Type, R[CSV+'Row']
          }}}}
  end

  F['view/csv'] = -> d,e {
    d.delete_if{|s,r|
      !(r.class==Hash &&
        r[Type].do{|t|
          t.class == Array &&
          t.map(&:maybeURI).member?(CSV+'Row')})}
    [F['view/p'][d,e],
     {_: :style, c: 'table.tab .abbr, table.tab .scheme {display: inline}'}]}

  # property-selector toolbar + tabular view (dynamic CSS on RDFa element-attributes)
  fn 'view/p',->d,e{
    #TODO fragmentURI scheme for selection-state
    [H.once(e,'property.toolbar',H.once(e,'p',(H.once e,:mu,H.js('/js/mu')),
     H.js('/js/p'),
     H.css('/css/table')),
     {_: :a, href: '#', c: '-', id: :hideP},
     {_: :a, href: '#', c: '+', id: :showP},
     {_: :span, id: 'properties',
       c: R.graphProperties(d).map{|k|
         {_: :a, class: :n, href: k, c: k.label+' '}}},
       {_: :style, id: :pS},
       {_: :style, id: :lS}),
     F['view/table'][d,e]]}

  F['view/'+CSV+'Row'] = NullView

end
