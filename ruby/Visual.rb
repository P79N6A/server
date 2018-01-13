class WebResource
  module HTML
    def htmlTree graph
      q = qs.empty? ? '?head' : qs
      # construct tree
      tree = {}
      graph.keys.select{|k|!k.R.host && k[-1]=='/'}.map{|uri| # local containers
        c = tree # start at root
        uri.R.parts.map{|name| # path instructions
          c = c[name] ||= {}}} # create node and jump cursor

      # renderer
      render = -> t,path='' {
        nodes = t.keys.sort
        label = 'p'+path.sha2 if nodes.size > 1
        @r[:label][label] = true if label
        tabled = nodes.size < 36
        sizes = []
        # scale
        nodes.map{|name|
          uri = path + name + '/'
          graph[uri].do{|r|
            r[Size].justArray.map{|sz|
              sizes.push sz}}} if label
        maxSize = sizes.max.to_f
        # output
        {_: tabled ? :table : :div, class: :tree, c: [
           {_: tabled ? :tr : :div, class: :nodes, c: nodes.map{|name| # nodes
              this = path + name + '/' # path
              s = graph[this].do{|r|r[Size].justArray[0]} # size
              named = !name.empty?
              scaled = sizes.size > 0 && s && tabled
              height = scaled && (s / maxSize) # scale
              {_: tabled ? :td : :div, style: scaled ? 'height: 8em' : '',
               c: named ? {_: :a, href: this + q, name: label, style: scaled ? "height:#{height * 100.0}%" : '',
                           c: CGI.escapeHTML(URI.unescape name) + (scaled ? '' : '/')} : ''}}.intersperse("\n")},"\n",
           ({_: tabled ? :tr : :div, c: nodes.map{|k| # children
              {_: tabled ? :td : :div, c: (render[t[k], path+k+'/'] if t[k].size > 0)}}.intersperse("\n")} unless !nodes.find{|n|t[n].size > 0})]}}

      # render
      render[tree]
    end
  end
end
