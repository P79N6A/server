# coding: utf-8
watch __FILE__
class R

  # paginate history-storage container
  FileSet['history'] = -> d,env,g {
    FileSet['page'][d.fragmentDir,env,g].map{|f|f.setEnv env}}

  Filter['edit'] = -> g,e { # add editor-typetags to resource(s)

    # new resource
    if e.q.has_key? 'new'
      if e[404]
        if e.q.has_key? 'type' # type bound
          e.q['edit'] = true   # ready to edit
        else                   # type selector
          g['#new'] = {Type => R['#untyped']}
        end
      else # post to target resource
        subject = g['#new'] = {Type => [R['#editable']]}
        e.q['type'].do{|t| subject[Type].push R[t.expand]}
        g[e.uri].do{|target|
          target[Type].justArray.map{|type| # container type
            Containers[type.uri].do{|ct| # containee type
              Create[ct].do{|c|c[subject,target,e]} # bespoke constructor
              subject[Type].push R[ct]}}}
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
      r[Label] ||= e.R.basename
      [LDP+'contains', Size, Creator, Mtime, SIOC+'has_container', SIOC+'has_parent',
      ].map{|p|r.delete p} # server-managed properties
    end}

  Creatable = {
    Container => [Forum, Wiki, Blog],
    Resource => [Resource, WikiArticle],
  }

  Render[WikiText] = -> texts {
    texts.justArray.map{|t|
      content = t[Content]
      case t['datatype']
      when 'markdown'
        ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render content
      when 'html'
        content
      when 'text'
        content.hrefs
      end}}

  # HTML type-selector controls
  ViewGroup['#untyped'] = -> graph, e {
    Creatable.map{|category,types|
      {style: 'background-color:#efefef;color:#000;border-radius:1em;float:left;padding:.8em;margin:.8em',
        c: types.map{|type|
        {_: :a, style: 'font-size: 2em; display:block',
         c: type.R.fragment, href: e['REQUEST_PATH']+'?new&type='+type.shorten}}
      }
    }
  }

  # editor CSS/JS
  ViewGroup['#editable'] = -> graph, e {
    [graph.map{|u,r|ViewA['#editable'][r,e]},
     H.js('/js/edit', true),
    H.css('/css/edit',true)]}

  # editor for one resource, as a HTML <form> element
  ViewA['#editable'] = -> re, e {
    e.q['type'].do{|t|re[Type] = t.expand.R}
    datatype = e.q['datatype'] || 'html'
    re[Type] ||= R[WikiArticle]
    re[Title] ||= ''
    re[WikiText] ||= ''
    re[Creator] ||= e.user
    {_: :form, method: :POST,
       c: [{_: :table, class: :html,
            c: [re.uri.do{|uri|
                  {_: :tr,
                   c: {_: :td, colspan: 2,
                       c: [{_: :a, class: :uri, c: uri, href: uri},
                           {_: :a, class: :history, c: :history, href: uri.sub('#','%23')+'?set=history'}]}}},
                 re.keys.map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, class: Icons[p], href: p, c: Type==p&&{_: :img,src: '/css/misc/cube.svg'}||Icons[p]&&''||p.R.fragment||p.R.basename}},
                         {_: :td, c: re[p].do{|o|
                             o.justArray.map{|o|
                               case p
                               when 'uri'
                                 [{_: :input, type: :hidden,  name: :uri, value: o}, o]
                               when Type
                                 {_: :input, name: Type, value: o.uri, size: 64} unless o.uri == '#editable'
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
                                 {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 64}
                               end }}}].cr}}].cr},
           {_: :a, id: :cancel, class: :cancel, href: e.uri, c: 'X'},
           {_: :input, type: :submit, value: 'write'}].cr}}

  def editLink env
    (env.R.join stripFrag) + (env[404] ? '?new' : '?edit') + (fragment ? ('&fragment=' + fragment) : '')
  end

end

module Th
  def editable r
    @editable ||= (
      signedIn &&            # webID required
      !q.has_key?('edit') && # already editing
      !q.has_key?('new') &&  # create + bind types first
      q['set']!='history' && # can't edit history
     (!r.host||r.host==host) # our resource, not a non-authoritive cache
    )
  end
end
