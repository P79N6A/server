class WebResource
  module HTML
    Markup[Container] = -> container , env {
      uri = container.delete 'uri'
      container.delete Type
      name = container.delete :name
      title = container.delete Title
      # content represented as singleton Object, Array or URI-keyed Hash
      contents = container.delete(Contains).do{|cs|cs.class == Hash ? cs.values : cs}.justArray
      {class: :container,
       c: [title ? Markup[Title][title.justArray[0], env, uri.justArray[0]] : {_: :span, class: :label, c: CGI.escapeHTML(name||'')},
           contents.map{|c|HTML.value(nil,c,env)},
           (HTML.kv(container, env) unless container.empty?)]}}

    Group['flat'] = -> graph { graph }
    # URI controls tree structure
    Group['tree'] = -> graph {
      tree = {}
      # select resource(s)
      (graph.class==Array ? graph : graph.values).map{|resource|
        cursor = tree
        r = resource.R
        # walk to document-graph location
        [r.host ? r.host.split('.').reverse : '',
         r.parts.map{|p|p.split '%23'}].flatten.map{|name|
          cursor[Type] ||= R[Container]
          cursor[Contains] ||= {}
           # create named-node if missing, advance cursor
          cursor = cursor[Contains][name] ||= {name: name,
                                               #Title => name,
                                               Type => R[Container]}}
        # reference to data
        if !r.fragment # document itself
          resource.map{|k,v|
            cursor[k] = cursor[k].justArray.concat v.justArray}
        else # resource local data
          cursor[Contains] ||= {}
          cursor[Contains][r.fragment] = resource
        end
      }; tree }

    # {k => v} table -> Markup
    def self.kv hash, env
      hash.delete :name
      ["\n",
       {_: :table,
        c: hash.sort_by{|k,vs|k.to_s}.reverse.map{|k,vs|
          type = k && k.R || '#untyped'.R
          [{_: :tr, name: type.fragment || type.basename,
            c: ["\n ",
                {_: :td, class: 'k', c: Markup[Type][type]},"\n ",
                {_: :td, class: 'v',
                 c: vs.justArray.map{|v| HTML.value k,v,env }.intersperse(' ')}]},
           "\n"]}}, "\n"]
    end

  end
end
