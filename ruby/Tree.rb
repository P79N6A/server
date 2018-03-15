class WebResource
  module HTML

    def self.kv hash
     hash.map{|k,vs|
       {class: :kv,
        c: [{class: :k, c: {_: :span, class: :label, c: k}},
            {class: :v,
             c: ["\n ",
                 vs.justArray.map{|v|
                   c = v.class
                   if c == Hash
                     kv v # another kv hash
                   elsif c == TrueClass
                     {_: :a, class: :check}
                   elsif c == FalseClass
                     {_: :a, class: :ban}
                   elsif !([Fixnum,String].member? c)
                     {_: :a, class: :cog, c: c}
                   else
                     CGI.escapeHTML v.to_s
                   end
                 }.intersperse(' ')]}]}}
    end

    def htmlTree graph
      tree = {}
      query = qs
      graph.keys.select{|k|!k.R.host}.map{|path|
        cur = tree
        path.R.parts.map{|dir|
          dir.split '-'
        }.flatten.map{|name|
          cur = cur[name] ||= {}}} # jump cursor to node, initializing if first visit

      HTML.kv tree
    end
  end
end
