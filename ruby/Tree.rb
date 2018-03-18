 class WebResource
  module HTML
#      hidden = q.has_key?('head') && self[Title].empty? && self[Abstract].empty? && self[Link].empty?
    def self.kv hash, flip=0
      flop = flip != 0 ? 0 : 1
      style = flop == 1 ? "background-color: black; color: white" : "background-color: white; color: black"
      {_: :table, c: hash.map{|k,vs|
         {_: :tr, class: :kv,
          c: [{_: :td, class: :k, style: style,
               c: {_: :a, class: Icons[k] || :label, c: Icons[k] ? '' : k}},
              {_: :td, class: :v, style: style,
               c: ["\n ",
                   vs.justArray.map{|v|
                     if Markup[k]
                       Markup[k].call v
                     elsif v.class == Hash
                       kv v, flop
                     elsif v.class == WebResource
                       v
                     elsif k == Content
                       v
                     elsif k == 'uri'
                       v.R
                     else
                       CGI.escapeHTML v.to_s
                     end
                   }.intersperse(' ')]}]}}}
    end

    def htmlTree graph
      tree = {}
      query = qs
      graph.keys.select{|k|!k.R.host}.map{|path|
        cur = tree
        path.R.parts.map{|name|
          name.split '-'
        }.flatten.map{|name|
          cur = cur[name] ||= (graph.delete(path) || {})}} # jump cursor to node, initializing if first visit

      HTML.kv tree
    end
  end
end
