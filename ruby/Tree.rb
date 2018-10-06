class WebResource
  module HTML
    Markup[Container] = -> container , env {
      uri = container.delete 'uri'
      container.delete Type
      name = container.delete :name
      title = container.delete Title
      # contents can be represented in singleton Object, Array or URI-keyed Hash
      contents = container.delete(Contains).do{|cs|
        cs.class == Hash ? cs.values : cs}.justArray
      blank = BlankLabel.member? name
      bold = BoldLabel.member? name
      {class: 'container' + (bold ? ' highlighted' : ''),
       c: [(title ? Markup[Title][title.justArray[0], env, uri.justArray[0]] : {_: :span, class: bold ? :bold : :label, c: CGI.escapeHTML(name||'')} unless blank),
           contents.map{|c|HTML.value(nil,c,env)},
           (HTML.kv(container, env) unless container.empty?)]}}

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

  end
end
