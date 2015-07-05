# coding: utf-8
#watch __FILE__
class R

  Creatable = {
    Container => [Forum, Wiki, Blog],
    Resource => [Resource, WikiArticle],
  }

  # paginate history-storage container
  FileSet['history'] = -> d,env,g {
    FileSet['page'][d.fragmentDir,env,g].map{|f|f.setEnv env}}

  Filter['#create'] = -> g,e {
    if e[404]
      type = e.q['type']
      g[''] = {Type => if type # type bound
                [R[type],R['#editable']]
              else # defer to type-selector
                R['#untyped']
              end}
    else # target exists - new member
      subject = g['#'] = {Type => [R['#editable']]}
      e.q['type'].do{|t| subject[Type].push R[t.expand]}
      g[e.uri].do{|target| # target resource
        target[Type].justArray.map{|type| # target type
          Containers[type.uri].do{|ct| # containee type
            Create[ct].do{|c|c[subject,target,e]} # create resource
            subject[Type].push R[ct]}}} # add type-tag
    end
  }

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
  EditorIncludes = -> {[H.js('/js/edit', true), H.css('/css/edit',true)]}
  ViewGroup['#editable'] = -> graph, e {[ graph.map{|u,r| ViewA['#editable'][r,e] }, EditorIncludes[]]}

  SaveButton = -> e {
    [{_: :a, id: :cancel, class: :cancel, href: e.uri+'?edit', c: 'X cancel'},
    {_: :input, class: :save, type: :submit, value: ' write '}]}

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
          SaveButton[e]].cr}}

  def editLink env
    (env.R.join stripFrag) + (env[404] ? '?new' : '?edit') + (fragment ? ('&fragment=' + fragment) : '')
  end

  EditableValue = -> p,o,env {
    if [Size, Creator, Mtime, LDP+'contains', SIOC+'has_container', SIOC+'has_parent'].member? p
    # can't edit server-managed values (basic provenance + containment)
    else
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
        {_: :textarea, name: p, c: o, rows: 8, cols: 48}
      when WikiText # HTML, Markdown, or plaintext
        datatype = env.q['datatype'] || 'html'
        [{_: :textarea, name: p, c: o[Content], rows: 8, cols: 48},'<br>',
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
        {_: :input, name: p, value: o.respond_to?(:uri) ? o.uri : o, size: 24}
      end
    end
  }

end

module Th
  def editable r=nil
    @editable ||= (
      signedIn &&                # user-ID required
      q['set']!='history' &&     # can't change history
     (!r||!r.host||r.host==host) # our resource, not a non-authoritive cache
    )
  end
end
