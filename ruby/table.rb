# coding: utf-8
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

  TabularView = ViewGroup[Directory] = ViewGroup[Stat+'File'] = ViewGroup[Resource] = ViewGroup[CSVns+'Row'] = -> g, e, show_head = true, show_id = true {

    sort = (e.q['sort']||'uri').expand                      # sort property
    direction = e.q.has_key?('reverse') ? :reverse : :id    # sort direction

    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq # base keys
    keys = keys - [Title, Label, Content, Image, Type, 'uri', Size]
    # put URI and typetag at beginning
    keys.unshift 'uri' if show_id
    keys.unshift Type
    keys.unshift Size
    rows = g.resources e         # sorted resources
    e.q['addProperty'].do{|p|
      p = p.expand
      keys.push p unless keys.member?(p)||!p.match(/^http/)
    }

    {_: :table, class: :tab,
     c: [({_: :thead,
           c: {_: :tr,
               c: [keys.map{|k|
                     q = e.q.merge({'sort' => k.shorten})
                     if direction == :reverse
                       q.delete 'reverse'
                     else
                       q['reverse'] = ''
                     end
                     [{_: :th,
                       property: k,
                       style: k == sort ? 'background-color:#0f0' : '',
                       c: {_: :a,
                           rel: :nofollow,
                           href: CGI.escapeHTML(q.qs),
                           class: Icons[k]||'',
                           c: k == Type ? '' : Icons[k] ? '' : (k.R.fragment||k.R.basename)}}, "\n"]},
                  ]}} if show_head),
         {_: :tbody, c: rows.map{|r|
            if r.uri == e.uri && r.uri[-1]=='/' # current directory
              r[LDP+'contains'].justArray.map{|c|
                dir = c.uri[-1] == '/'
                e[:sidebar].concat ['<br>',{_: :a, class: :dir, href: c.uri, c: c.R.basename}] if dir
              }
              nil
              TableRow[{'uri' => '..', Label => '↑'},e,sort,direction,keys] unless r.R.path=='/'
            else
              TableRow[r,e,sort,direction,keys]
            end
          }}]}}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    [{_: :tr, id: this.path, href: l.uri,
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: case k
                 when 'uri'
                   {_: :a, href: (CGI.escapeHTML l.uri),
                    c: CGI.escapeHTML((l[Title]||l[Label]||this.basename).justArray[0])} if l.uri
                 when Type
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     {_: :a, href: CGI.escapeHTML(l.uri), c: icon ? '' : (t.R.fragment||t.R.basename), class: icon}}
                 when LDP+'contains'
                   l[k].do{|children|
                     children = children.justArray
                     if children[0].keys.size > 1 # tabular-view for children w/ data
                       childGraph = {}
                       children.map{|c|childGraph[c.uri] = c}
                       TabularView[childGraph,e,false]
                     else
                       children.map{|c|[c.R, ' ']}
                     end
                   }
                 when WikiText
                   Render[WikiText][l[k]]
                 when DC+'tag'
                   l[k].justArray.map{|v|
                     e[:label][v] = true
                     [{_: :a, href: '#', name: v, c: v},' ']}
                 else
                   l[k].justArray.map{|v|
                     case v
                     when Hash
                       v.R
                     else
                       v
                     end
                   }.intersperse(' ')
                 end}, "\n"]}]},
     l[Content].do{|c|{_: :tr, c: {_: :td, class: :content, colspan: keys.size, c: c}}},
     l[Image].do{|c|
       {_: :tr,
        c: {_: :td, colspan: keys.size,
            c: c.justArray.map{|i|{_: :a, href: l.uri, c: {_: :img, src: i.uri, class: :tablePreview}}}.intersperse(' ')}}}]}

  # tabular view for schema types
  ViewGroup[RDFClass] =
    ViewGroup[RDFs+'Datatype'] =
    ViewGroup[Property] =
    ViewGroup[OWL+'Class'] =
    ViewGroup[OWL+'Ontology'] =
    ViewGroup[OWL+'ObjectProperty'] =
    ViewGroup[OWL+'DatatypeProperty'] =
    ViewGroup[OWL+'SymmetricProperty'] =
    ViewGroup[OWL+'TransitiveProperty'] =
    TabularView

end
