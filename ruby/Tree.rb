class WebResource
  module HTML
    # container tree-structure in HTML
    def htmlTree graph
      q = qs.empty? ? '?head' : qs

      # construct tree
      tree = {}
      graph.keys.select{|k|!k.R.host && k[-1]=='/'}.map{|uri| # local containers
        c = tree # start at root
        uri.R.parts.map{|name| # path instructions
          c = c[name] ||= {}}} # create node and jump cursor

      # render function
      render = -> t,path='' {
        nodes = t.keys.sort - %w{msg}
        label = 'p'+path.sha2 if nodes.size > 1
        @r[:label][label] = true if label
        sizes = []

        # scale nodes
        nodes.map{|name|
          uri = path + name + '/'
          graph[uri].do{|r|
            r[Size].justArray.map{|sz|
              sizes.push sz}}} if label
        maxSize = sizes.max.to_f

        # output
        {_: :table, class: :tree, c: [
           ({_: :tr, c: nodes.map{|k|
               {_: :td, c: (render[t[k], path+k+'/'] if t[k].size > 0)}}.intersperse("\n")} unless !nodes.find{|n|t[n].size > 0}),
           {_: :tr, class: :nodes, c: nodes.map{|name|
              this = path + name + '/' # path
              s = graph[this].do{|r|   # size
                r.delete(Size).justArray[0]}
              named = !name.empty?
              scaled = s && sizes.size > 0
              height = scaled && (s / maxSize) # scale
              {_: :td, style: scaled ? 'height: 8em' : '',
               c: named ? {_: :a, id: 't'+this.gsub(/[^a-zA-Z0-9]/,'_'), href: this + q, name: label, style: scaled ? "height:#{height * 100.0}%" : '',
                           c: CGI.escapeHTML(URI.unescape(name)[0..24])} : ''}}.intersperse("\n")},"\n",
         ]}}

      # render
      render[tree]
    end
  end
end
