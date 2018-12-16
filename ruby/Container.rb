class WebResource
  module HTML

    # default grouping. URI-indexed, no subcontainers
    Group['flat'] = -> graph { graph }

    # build tree from URI path component
    Group['tree'] = -> graph {
      tree = {}

      # for each graph-node
      (graph.class==Array ? graph : graph.values).map{|resource|
        cursor = tree
        r = resource.R

        # locate document-graph
        [r.host || '',
         r.parts.map{|p|p.split '%23'}].flatten.map{|name|
          cursor[Type] ||= R[Container]
          cursor[Contains] ||= {}
           # advance cursor to node, creating as needed
          cursor = cursor[Contains][name] ||= {name: name, Type => R[Container]}}

        # place data in named-graph
        if !r.fragment # graph-document itself
          resource.map{|k,v|
            cursor[k] = cursor[k].justArray.concat v.justArray}
        else # graph-doc contained resource
          cursor[Contains] ||= {}
          cursor[Contains][r.fragment] = resource
        end}

      tree }

    Markup[Container] = -> container , env {

      container.delete Type
      uri = container.delete 'uri'
      name = container.delete :name
      title = container.delete Title
      color = '#%06x' % (rand 16777216)
      contents = container.delete(Contains).do{|cs|
        # children representable as an Object, array of Object, or URI-indexed table
        cs.class == Hash ? cs.values : cs}.justArray

      {class: :container, style: "background: repeating-linear-gradient( -45deg, #000000, #000000 .92em, #{color} .92em, #{color} 1em ); border: .08em solid #{color}",
       c: [title ? Markup[Title][title.justArray[0], env, uri.justArray[0]] : (name ? ("<span class=name style='background-color: #{color}'>"+(CGI.escapeHTML name) + "</span>") : ''),
           contents.map{|c|
             HTML.value(nil,c,env)},
           # extra container metadata
           (HTML.kv(container, env) unless container.empty?)]}}

    # {k => v} -> Markup
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
