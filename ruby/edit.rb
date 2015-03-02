#watch __FILE__
class R

  Filter['edit'] = -> g,e {

    # new resource
    if e.q.has_key? 'new'
      if e[404] # target nonexistent
        if e.q.has_key? 'type' # type bound
          e.q['edit'] = true   # ready to edit
        else                   # type selector
          g['#new'] = {Type => R['#untyped']}
        end
      else # target exists, new post to it
        g['#new'] = {Type => [R['#editable'], # no URI, POST-handler will decide
                              e.q['type'].do{|t| R[t.expand]} || R[Resource]]} # type
        g[e.uri].do{|container|# target
          container[Type].justArray.map{|type|Containers[type.uri]}. # lookup contained-type
            compact[0].do{|childType|g['#new'][Type].push R[childType]}}# add contained-type
      end
    end

    # edit resource
    if e.q.has_key? 'edit'
      fragment = e.q['fragment']
      r = if fragment
            fragURI = '#' + fragment
            re = g.values.find{|u,r|u.R.fragment == fragment} || # found in doc
                 (g[fragURI] = {})                               # create new
            re['uri'] = fragURI                                  # identify
            re
          else
            g[e.uri] ||= {} # no fragment - doc or container itself
          end
      r[Type] ||= []              # init Type field
      r[Type].push R['#editable'] # attach 'editable' type
      r[Title] ||= e.R.basename   # suggest a title
      [LDP+'contains', Size, Creator, SIOC+'has_container'].map{|p|r.delete p} # ambient properties, not editable
    end}

  Creatable = [Forum, Wiki, WikiArticle, BlogPost]

  ViewGroup['#untyped'] = -> graph, e {
    Creatable.map{|c|
      {_: :a, style: 'font-size: 2em; display:block', c: c.R.fragment,
       href: e['REQUEST_PATH']+'?new&type='+c.shorten}}}

  ViewGroup['#editable'] = -> graph, e {
    [graph.map{|u,r|ViewA['#editable'][r,e]},
     H.css('/css/edit'), H.css('/css/html')]}

  ViewA['#editable'] = -> re, e {
    e.q['type'].do{|t|re[Type] = t.expand.R}
    datatype = e.q['datatype'] || 'markdown'
    re[Title] ||= ''
    re[WikiText] ||= ''
     {_: :form, method: :POST,
       c: [{_: :table, class: :html,
             c: [{_: :tr, c: {_: :td, colspan: 2,
                     c: {_: :a, class: :uri, c: re.uri, href: re.uri}}},
                 re.keys.map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, href: p, c: p.R.abbr}},
                         {_: :td, c: re[p].do{|o|
                             o.justArray.map{|o|
                               case p
                               when 'uri'
                                 [{_: :input, type: :hidden,  name: :uri, value: o}, o]
                               when Type
                                 unless ['#editable', Directory].member?(o.uri)
                                   [{_: :input, type: :hidden,  name: Type, value: o.uri}, o.R.href]
                                 end
                               when Content # RDF:HTML literal
                                 {_: :textarea, name: p, c: o, rows: 16, cols: 80}
                               when WikiText # HTML, Markdown, or plaintext
                                 [{_: :textarea, name: p, c: o[Content], rows: 16, cols: 80},
                                  %w{html markdown text}.map{|f|
                                    if f == datatype
                                      [{_: :b, c: f},
                                       {_: :input, type: :hidden, name: :datatype, value: f}]
                                    else
                                      {_: :a, class: :datatype, href: e.q.merge({'datatype' => f}).qs, c: f}
                                    end
                                  }.intersperse(' ')]
                               when Date
                                 {_: :b, c: [o,' ']}
                               when Size
                                 [o,' ']
                               else
                                 {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 54}
                               end }}}].cr}}].cr},
           {_: :a, class: :cancel, href: e.uri, c: 'X'},
           {_: :input, type: :submit, value: 'write'}].cr}}

  def editLink env
    doc = env.R
    doc.join(self).R.docroot + '?edit&fragment=' + fragName
  end

end
