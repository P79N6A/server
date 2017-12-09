class R

  Search = -> graph,re {
    grep = re.path.split('/').size > 3 # suggested search-provider based on tree depth
    {class: :search,
     c: [re.env[:Links][:prev].do{|p|{_: :a, id: :prev, c: '&#9664;', href: (CGI.escapeHTML p.to_s)}},
         (query = re.q['q'] || re.q['f']
          {_: :form,
           c: [{_: :a, class: :find, href: (query ? '?' : '') + '#searchbox' },
               {_: :input, id: :searchbox,
                name: grep ? 'q' : 'f',
                placeholder: grep ? :grep : :find
               }.update(query ? {value: query} : {})]} unless re.path=='/'),
         re.env[:Links][:next].do{|n|{_: :a, id: :next, c: '&#9654;', href: (CGI.escapeHTML n.to_s)}}]}}

  # interface with some online services
  
  Twitter = 'https://twitter.com'
  def fetchTweets
    nokogiri.css('div.tweet > div.content').map{|t|
      s = Twitter + t.css('.js-permalink').attr('href')
      authorName = t.css('.username b')[0].inner_text
      author = R[Twitter + '/' + authorName]
      ts = Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      yield s, Type, R[SIOC+'Tweet']
      yield s, Date, ts
      yield s, Creator, author
      yield s, To, (Twitter + '/#twitter').R
      yield s, Label, authorName
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a|
        a.set_attribute('href', Twitter + (a.attr 'href')) if (a.attr 'href').match /^\//
        yield s, DC+'link', R[a.attr 'href']}
      yield s, Abstract, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end
  def indexTweets
    graph = {}
    # build graph
    fetchTweets{|s,p,o|
      graph[s] ||= {'uri'=>s}
      graph[s][p] ||= []
      graph[s][p].push o}
    # serialize tweets to file(s)
    graph.map{|u,r|
      r[Date].do{|t|
        slug = (u.sub(/https?/,'.').gsub(/\W/,'.')).gsub /\.+/,'.'
        time = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        doc = "/#{time}#{slug}.e".R
        unless doc.e
          puts u
          doc.writeFile({u => r}.to_json)
        end}}
  end
  def twitter
    open(pathPOSIX).readlines.map(&:chomp).shuffle.each_slice(16){|s|
      readURI = Twitter + '/search?f=tweets&vertical=default&q=' + s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
      readURI.R.indexTweets}
  end

  Instagram = 'https://www.instagram.com/'
  def ig
    open(pathPOSIX).readlines.map(&:chomp).map{|ig|
      R[Instagram+ig].indexInstagram}
  end
  Tree = -> graph,re {
    qs = R.qs re.q.merge({'head'=>''})
    tree = {}; tile = 0

    # construct tree
    graph.keys.select{|k|!k.R.host && k[-1]=='/'}.map{|uri|
      c = tree
      uri.R.parts.map{|name| # path instructions
        c = c[name] ||= {}}} # create node and jump cursor

    sizes = []
    scale = -> t,path='' {
      nodes = t.keys - TabularFields
      nodes.map{|name|
        this = path + name + '/'
        nodes.size > 1 && graph[this].do{|r|sizes.concat r[Size].justArray} # size
        scale[t[name], this] if t[name].size > 0}} # visit children
    scale[tree]
    size = sizes.max.to_f # max-size

    # renderer
    render = -> t,path='' {
      label = 'p'+path.sha2
      re.env[:label][label] = true
      nodes = t.keys.sort - TabularFields
      {_: :table, class: :tree, c: [
         {_: :tr, class: :name, c: nodes.map{|name| # nodes
            this = path + name + '/' # path
            s = nodes.size > 1 && graph[this].do{|r|r[Size].justArray[0]} # size
            graph.delete this # consume node
            tile += 1 unless s # odd/even toggle
            height = (s && size) ? (8.8 * s / size) : 1.0 # scale
            {_: :td, class: s ? :scaled : :node, # render
             c: {_: :a, href: this + qs, name: s ? label : :node, id: 't'+this.sha2,
                 style: s ? "height:#{height < 1.0 ? 1.0 : height}em" : (tile % 2 == 0 ? 'background-color:#222' : ''),
                 c: CGI.escapeHTML(URI.unescape name)}}}.intersperse("\n")},"\n",
         {_: :tr, c: nodes.map{|k| # child nodes
            {_: :td, c: (render[t[k], path+k+'/'] if t[k].size > 0)}}.intersperse("\n")}]}}
    render[tree]}

  Grep = -> graph, q {
    wordIndex = {}
    args = q.shellsplit
    args.each_with_index{|arg,i| wordIndex[arg] = i }
    pattern = /(#{args.join '|'})/i
    # select resources
    graph.map{|u,r|
      keep = r.to_s.match(pattern) || r[Type] == Container
      graph.delete u unless keep}
    # highlight matches
    graph.values.map{|r|
      (r[Content]||r[Abstract]).justArray.map(&:lines).flatten.grep(pattern).do{|lines|
        r[Abstract] = [lines[0..5].map{|l|
          l.gsub(/<[^>]+>/,'')[0..512].gsub(pattern){|g| # capture match
            H({_: :span, class: "w#{wordIndex[g.downcase]}", c: g}) # wrap match
          }},{_: :hr}] if lines.size > 0 }}
    # CSS
    graph['#abstracts'] = {Abstract => {_: :style, c: wordIndex.values.map{|i|".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}}}
    graph}


end
