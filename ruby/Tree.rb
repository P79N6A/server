 class WebResource
  module HTML

    def self.kv hash, flip=0
      flop = flip != 0 ? 0 : 1
      style = flop == 1 ? "background-color: black; color: white" : "background-color: white; color: black"
      {_: :table, c: hash.map{|k,vs|
         {_: :tr, class: :kv,
          c: [{_: :td, style: style, c: {_: :span, class: :label, c: k}},
              {_: :td, style: style,
               c: ["\n ",
                   vs.justArray.map{|v|
                     c = v.class
                     if c == Hash
                       kv v, flop
                     elsif c == TrueClass
                       {_: :a, class: :check}
                     elsif c == FalseClass
                       {_: :a, class: :ban}
                     elsif !([Fixnum,String].member? c)
                       {_: :a, class: :cog, c: c}
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
