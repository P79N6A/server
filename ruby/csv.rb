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

  TabularView = ViewGroup[CSVns+'Row'] = -> g,e {
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    sort = (e.q['sort']||'uri').expand
    order = e.q.has_key?('reverse') ? :reverse : :id
    {_: :table, :class => :tab,
     c: [H.css('/css/table'),
         {_: :tr, c: keys.map{|k|
            this = sort == k
            q = e.q.merge({'sort' => k.shorten})
            if order == :reverse
              q.delete 'reverse'
            else
              q['reverse'] = ''
            end
            {_: :th, class: :label, property: k,
             c: {_: :a, rel: :nofollow,
                 class: this ? :this : :that,
                  href: q.qs,
                     c: k.R.abbr}}}},
         g.resources(e).send(order).map{|e|
           {_: :tr, about: e.uri, c: keys.map{|k|
              this = sort == k
              {_: :td, property: k, class: this ? :this : :that,
               c: k=='uri' ? e.R.do{|r|
                               {_: :a, href: r.uri, c: e[Title]||e[Label]||r.basename}
                             } : e[k].html}}}}.cr]}}

end
