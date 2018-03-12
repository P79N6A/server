class WebResource
  module HTML
    def htmlTree graph
      query = qs
#     construct
      tree = {}
      graph.keys.select{|k|!k.R.host && k[-1]=='/'}.map{|uri|
        c = tree # start at root
        uri.R.parts.map{|dir|
          dir.split '-'
        }.flatten.map{|name| # path instructions
          c = c[name] ||= {}}} # create node and jump cursor
#     render
      HTML.kv tree
    end
  end
end
