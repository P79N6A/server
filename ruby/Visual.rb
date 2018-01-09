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
        size = 0.0
        # scale
        nodes.map{|name|
          uri = path + name + '/'
          graph[uri].do{|r|
            r[Size].justArray.map{|sz|
              size += sz}}} if label
        # output
        {_: tabled ? :table : :div, class: :tree, c: [
           {_: tabled ? :tr : :div, class: :nodes, c: nodes.map{|name| # nodes
              this = path + name + '/' # path
              s = graph[this].do{|r|r[Size].justArray[0]} # size
              named = !name.empty?
              scaled = size > 0 && s && tabled
              width = scaled && (s / size) # scale
              {_: tabled ? :td : :div,
               style: scaled ? "width:#{width * 100.0}%" : '',
               c: named ? {_: :a, href: this + q, name: label, class: scaled ? :scaled : '',
                           c: (scaled ? '' : ('&nbsp;'*path.size)) + CGI.escapeHTML(URI.unescape name) + (scaled ? '' : '/')} : ''}}.intersperse("\n")},"\n",
           ({_: tabled ? :tr : :div, c: nodes.map{|k| # children
              {_: tabled ? :td : :div, c: (render[t[k], path+k+'/'] if t[k].size > 0)}}.intersperse("\n")} unless !nodes.find{|n|t[n].size > 0})]}}

      # render tree
      render[tree]
    end
  end
end
