# coding: utf-8
#watch __FILE__
class R

  FileSet['history'] = -> d,env,g {# paginate internal history-storage container
    FileSet['page'][d.fragmentDir,env,g].map{|f|f.setEnv env}}

  Filter['edit'] = -> g,e { # add editor-resource to response

    # new resource
    if e.q.has_key? 'new'
      if e[404] # target nonexistent
        if e.q.has_key? 'type' # type bound
          e.q['edit'] = true   # ready to edit
        else                   # type selector
          g['#new'] = {Type => R['#untyped']}
        end
      else # target exists, new post to it
        g['#new'] = {Type => [R['#editable']]}
        e.q['type'].do{|t| g['#new'][Type].push R[t.expand]}
        g[e.uri].do{|t| # target
          t[Type].justArray.map{|type| # target types
            Containers[type.uri].do{|ct| # contained type
              g['#new'][Type].push R[ct]}}}
      end
    end

    # edit resource
    if e.q.has_key? 'edit'
      uri = e.uri
      if e.q['fragment']
        uri = uri + '#' + e.q['fragment']
      end
      r = g[uri] ||= {} # resource
      r[Type] ||= []
      r[Type].push R['#editable']
      r[Title] ||= e.R.basename # suggest a title
      [LDP+'contains', Size, Creator, Mtime,
       SIOC+'has_container',
       SIOC+'has_parent',
      ].map{|p|r.delete p} # ambient properties, not editable
    end}

  Creatable = [Forum, Wiki, WikiArticle, BlogPost]

  Render[WikiText] = -> texts {
    texts.justArray.map{|t|
      content = t[Content]
      case t['datatype']
      when 'markdown'
        ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render content
      when 'html'
        StripHTML[content]
      when 'text'
        content.hrefs
      end}}

  # present type-selection dialog
  ViewGroup['#untyped'] = -> graph, e {
    Creatable.map{|c|
      {_: :a, style: 'font-size: 2em; display:block', c: c.R.fragment,
       href: e['REQUEST_PATH']+'?new&type='+c.shorten}}}

  # show editor for each editable resource + edit CSS once
  ViewGroup['#editable'] = -> graph, e {[graph.map{|u,r|ViewA['#editable'][r,e]},H.css('/css/edit')]}

  # HTML based editor. <form> and URI-keys
  ViewA['#editable'] = -> re, e {
    e.q['type'].do{|t|re[Type] = t.expand.R}
    datatype = e.q['datatype'] || 'html'
    re[Title] ||= ''
    re[WikiText] ||= ''
    re[Type] ||= R[WikiArticle]
     {_: :form, method: :POST,
       c: [{_: :table, class: :html,
            c: [re.uri.do{|uri|
                  {_: :tr,
                   c: {_: :td, colspan: 2,
                       c: [{_: :a, class: :uri, c: uri, href: uri},
                           {_: :a, class: :history, c: :history, href: uri.sub('#','%23')+'?set=history'},
                          ]}}},
                 re.keys.map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, href: p, c: p.R.abbr}},
                         {_: :td, c: re[p].do{|o|
                             o.justArray.map{|o|
                               case p
                               when 'uri'
                                 [{_: :input, type: :hidden,  name: :uri, value: o}, o]
                               when Type
                                 {_: :input, name: Type, value: o.uri, size: 54} unless o.uri == '#editable'
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
    (env.R.join stripFrag) + '?' + (env[404] ? 'new' : 'edit') + (fragment ? ('&fragment=' + fragment) : '')
  end

end

module Th
  def editable
    @editable ||= (signedIn && !q.has_key?('edit') && !q.has_key?('new') && q['set']!='history')
  end
end
