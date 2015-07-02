# coding: utf-8
watch __FILE__
class R

  Creatable = {
    Container => [Forum, Wiki, Blog],
    Resource => [Resource, WikiArticle],
  }

  # paginate history-storage container
  FileSet['history'] = -> d,env,g {
    FileSet['page'][d.fragmentDir,env,g].map{|f|f.setEnv env}}

  Filter['edit'] = -> g,e { # add editor-typetags to resource(s)

    # add new resource
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

    # make resource editable
    if e.q.has_key? 'edit'
      uri = e.uri
      if e.q['fragment']
        uri = uri + '#' + e.q['fragment']
      end
      r = g[uri] ||= {} # resource
      r[Type] ||= []
      r[Type].push R['#editable']
      r[Label] ||= e.R.basename

      [Size, Creator, Mtime, LDP+'contains', SIOC+'has_container', SIOC+'has_parent'].
        map{|p|r.delete p} # can't edit server-managed properties (basic provenance + containment)
    end}

  # HTML type-selector controls
  ViewGroup['#untyped'] = -> graph, e {
    Creatable.map{|category,types|
      {style: 'background-color:#efefef;color:#000;border-radius:1em;float:left;padding:0 .8em .8em .8em;margin:.8em',
       c: [{_: :a, style: 'color:#000;font-size:2em', class: Icons[category]},
         types.map{|type|
           {_: :a, class: Icons[type],style: 'font-size: 2em; display:block;color:#333;text-decoration:none',
            c: type.R.fragment, href: e['REQUEST_PATH']+'?new&type='+type.shorten}}]
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
    re[Type] ||= R[WikiArticle]
    re[Title] ||= ''
    re[WikiText] ||= ''
    re[Creator] ||= e.user
    {_: :form, method: :POST,
       c: [{_: :table, class: :html,
            c: [re.uri.do{|uri|
                  {_: :tr,
                   c: {_: :td, colspan: 2,
                       c: {_: :a, class: :history, c: :history, href: uri.sub('#','%23')+'?set=history'}}}},
                 re.keys.map{|p|
                   {_: :tr,
                     c: [{_: :td, class: :key, c: {_: :a, class: Icons[p], href: p, c: Icons[p]&&''||p.R.fragment||p.R.basename}},
                         {_: :td, c: re[p].do{|o|
                             o.justArray.map{|o|
                               EditableValue[p,o,e]
                             }}}].cr}}].cr},
           {_: :a, id: :cancel, class: :cancel, href: e.uri, c: 'X cancel'},
           {_: :input, type: :submit, value: '+ save'}].cr}}

  def editLink env
    (env.R.join stripFrag) + (env[404] ? '?new' : '?edit') + (fragment ? ('&fragment=' + fragment) : '')
  end

  EditableValue = -> p,o,env {
    case p
    when 'uri'
      [{_: :input, type: :hidden,  name: :uri, value: o}, o]
    when Type
      unless o.uri == '#editable'
        [{_: :input, name: Type, value: o.uri, type: :hidden},
         {_: :a, class: Icons[o.uri], title: o.uri}
        ]
      end
    when Content # RDF:HTML literal
      {_: :textarea, name: p, c: o, rows: 16, cols: 80}
    when WikiText # HTML, Markdown, or plaintext
      datatype = env.q['datatype'] || 'html'
      [{_: :textarea, name: p, c: o[Content], rows: 16, cols: 80},'<br>',
       %w{html markdown text}.map{|f|
         if f == datatype
           [{_: :b, c: f},
            {_: :input, type: :hidden, name: :datatype, value: f}]
         else
           {_: :a, class: :datatype, href: env.q.merge({'datatype' => f}).qs, c: f}
         end
       }.intersperse(' ')]
    when Date
      {_: :b, c: [o,' ']}
    when Size
      [o,' ']
    else
      {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 64}
    end}

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
