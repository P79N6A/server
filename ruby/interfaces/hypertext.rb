class R

  def nokogiri; Nokogiri::HTML.parse (open uri).read end

  # used by the default view, don't show in dedicated column
  InlineMeta = [Title, Image, Abstract, Content, Label, DC+'hasFormat', SIOC+'attachment', SIOC+'user_agent', Stat+'contains']

  # properties hidden without verbose flag
  VerboseMeta = [DC+'identifier', DC+'source', DCe+'rights', DCe+'publisher',
                 RSS+'comments', RSS+'em', RSS+'category', Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',
                 SIOC+'has_discussion', SIOC+'reply_of', SIOC+'num_replies', Mtime, Podcast+'explicit', Podcast+'summary', Comments,"http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content"]

  HTML = -> graph, re {
    e = re.env
    e[:title] = graph[re.path+'#this'].do{|r|r[Title].justArray[0]}
    e[:label] = {}
    empty = graph.empty?
    if q = re.q['q']
      Grep[graph,q]
    end
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'}, {_: :title, c: e[:title]||re.path}, {_: :link, rel: :icon, href: '/.conf/icon.png'},
                 %w{code icons site}.map{|s|{_: :style, c: ".conf/#{s}.css".R.readFile}},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}
                   }},
                 {_: :script, c: '.conf/site.js'.R.readFile}]},
            {_: :body,
             c: [e[:Links][:up].do{|p|[{_: :a, id: :up, c: '&#9650;', href: (CGI.escapeHTML p.to_s)},'<br>']},
                 e[:Links][:prev].do{|p|{_: :a, id: :prev, c: '&#9664;', href: (CGI.escapeHTML p.to_s)}},
                 Search[graph,re],
                 Tree[graph,re],
                 (Table[graph,re] unless graph.empty?),
                 {_: :style, c: e[:label].map{|name,_|
                    "[name=\"#{name}\"] {color:#000;background-color: #{'#%06x' % (rand 16777216)}}\n"}},
                 !empty && e[:Links][:down].do{|d|
                   {_: :a, id: :down, c: '&#9660;', href: (CGI.escapeHTML d.to_s)}},
                 empty && {_: :a, id: :nope, class: :notfound, c: '404'+'<br>'*7, href: re.dirname},
                 e[:Links][:next].do{|n|{_: :a, id: :next, c: '&#9654;', href: (CGI.escapeHTML n.to_s)}}
                ]}]}]}

  Tree = -> graph,re {
    # construct tree
    tree = {}
    graph.keys.select{|k|!k.R.host && k[-1]=='/'}.map{|uri|
      c = tree
      uri.R.parts.map{|name| # path instructions
        c = c[name] ||= {}}} # create node and jump cursor
    # find sizes of scaled nodes
    sizes = []
    scale = -> t,path='' {
      t.keys.map{|name|
        this = path+name+'/'
        graph[this].do{|r|
          sizes.concat r[Size].justArray} # size
        scale[t[name], this] if t[name].size > 0}} # child nodes
    scale[tree]
    size = sizes.max.to_f # max-size

    # renderer
    render = -> t,path='' {
      label = 'p'+path.sha2
      re.env[:label][label] = true
      nodes = t.keys.sort
      table = nodes.size < 32
      {class: table ? :table : '', c: [
         {class: table ? :tr : '', c: nodes.map{|name| # nodes
            this = path + name + '/' # path
            s = graph[this].do{|r|r[Size].justArray[0]} # size
            graph.delete this # consume node
            height = (s && size) ? (8.8 * s / size) : 1.0 # scale
            {class: table ? :td : '', # render
             c: {_: :a, class: :scale, href: this + re.qs, name: s ? label : :node, id: 't'+this.sha2,
                 style: s ? "height:#{height < 1.0 ? 1.0 : height}em" : '',
                 c: CGI.escapeHTML(URI.unescape name)}}}.intersperse("\n")},"\n",
         {class: table ? :tr : '', c: nodes.map{|k| # child nodes
            {class: table ? :td : '', c: (render[t[k], path+k+'/'] if t[k].size > 0)}}.intersperse("\n")}]}}
    render[tree]}

  Table = -> g, e {
    (1..10).map{|i|e.env[:label]["quote"+i.to_s] = true} # labels
    [:links,:images].map{|p| e.env[p] = []} # link & image lists
    p = e.q['sort'] || Date
    direction = e.q.has_key?('ascending') ? :id : :reverse
    datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
    keys = g.values.map(&:keys).flatten.uniq - InlineMeta
    keys -= VerboseMeta unless e.q.has_key? 'full'
    [{_: :table, style: 'margin:auto',
      c: [{_: :tbody,
           c: g.values.sort_by{|s|((p=='uri' ? (s[Title]||s[Label]||s.uri) : s[p]).justArray[0]||0).send datatype}.send(direction).map{|r|
             TableRow[r,e,p,direction,keys]}.intersperse("\n")},
          {_: :tr, c: keys.map{|k| # header row
             selection = p == k
             q = e.q.merge({'sort' => k})
             if direction == :id # direction toggle
               q.delete 'ascending'
             else
               q['ascending'] = ''
             end
             href = CGI.escapeHTML R.qs q
             {_: :th, property: k, class: selection ? 'selected' : '',
              c: [{_: :a,href: href,class: Icons[k]||'',c: Icons[k] ? '' : (k.R.fragment||k.R.basename)},
                  (selection ? {_: :link, rel: :sort, href: href} : '')]}}}]},
     {_: :style, c: "[property=\"#{p}\"] {border-color:#444;border-style: solid; border-width: 0 0 .08em 0}"}]}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    inDoc = e.path == this.path
    reqURI = inDoc && !this.fragment
    identified = false
    href = this.uri
    head = e.q.has_key? 'head'
    types = l.types
    chat = types.member? SIOC+'InstantMessage'
    mail = types.member? SIOC+'MailMessage'
    post = types.member? SIOC+'BlogPost'
    tweet = types.member? SIOC+'Tweet'
    monospace = chat || mail || types.member?(SIOC+'SourceCode')
    date = l[Date].justArray.sort[-1]
    datePath = '/' + date[0..13].gsub(/[-T:]/,'/') if date
    titles = l[Title].justArray

    linkTable = -> links {
      links = links.map(&:R).select{|l|!e.env[:links].member? l} # unseen
      {_: :table, class: :links,
       c: links.group_by(&:host).map{|host,links|
         tld = host.split('.')[-1] || '' if host
         traverse = links.size <= 3
         e.env[:label][tld] = true
         {_: :tr,
          c: [({_: :td, class: :host, name: tld,
                c: {_: :a, href: '//'+host, c: host}} if host),
              {_: :td, class: :path, colspan: host ? 1 : 2,
               c: links.map{|link| e.env[:links].push link
                 [{_: :a, href: link.uri, c: CGI.escapeHTML(URI.unescape((link.host ? link.path : link.basename)||''))}.update(traverse ? {id: 'link'+rand.to_s.sha2} : {}),
                  ' ']}}]}}} unless links.empty? }
    rowID = -> {
      if identified || reqURI
        {}
      else
        identified = true
        # fragments from other docs could collide, so make a new one
        {id: (inDoc && this.fragment) ? this.fragment : 'r'+href.sha2}
      end}

    # pointer to selection of node in an index context
    indexLink = -> v {
      v = v.R
      if mail # messages*month
        {_: :a, id: 'address_'+rand.to_s.sha2, href: v.path + '?head#r' + href.sha2, c: v.label}
      elsif tweet # tweets*hour
        {_: :a, href: datePath + '*twitter*#r' + href.sha2, c: v.label}
      elsif post
        url = if datePath # host*month
                datePath[0..-4] + '*/*' + (v.host||'') + '*#r' + href.sha2
              else
                v.host
              end
        {_: :a, id: 'post_'+rand.to_s.sha2, href: url, c: v.label}
      else
        v
      end}

    unless head && titles.empty? && !l[Abstract]
      link = href + (!this.host && href[-1]=='/' && '?head' || '')
      {_: :tr,
       c: keys.map{|k|
         {_: :td, property: k,
          c: case k
             when 'uri'
               [l[Label].justArray.compact.map{|v|
                  label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                  lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                  e.env[:label][lbl] = true
                  {_: :a, class: :label, href: link, name: lbl, c: (CGI.escapeHTML label[0..41])}.update(rowID[])}.intersperse(' '),' ',
                titles.compact.map{|t|
                  {_: :a, class: :title, href: link, c: (CGI.escapeHTML t.to_s)}.update(rowID[]).update(reqURI ? {class: :reqURI} : {})}.intersperse(' '),
                linkTable[[SIOC+'attachment',Stat+'contains'].map{|p|l[p]}.flatten.compact],
                l[Abstract],
                (l[Content].justArray.map{|c|monospace ? {_: :pre,c: c} : [c,' ']} unless head),
                (images = []
                 images.push this if types.member?(Image) # subject of triple
                 l[Image].do{|i|images.concat i}          # object of triple
                 images.map(&:R).select{|i|!e.env[:images].member? i}.map{|img| # unseen images
                   e.env[:images].push img # seen
                   {_: :a, class: :thumb, href: href,
                    c: {_: :img, src: if !img.host || e.host==img.host
                         img.path + '?preview'
                       else
                         img.uri
                        end}}})]
             when Type
               l[Type].justArray.uniq.select{|t|t.respond_to? :uri}.map{|t|
                 {_: :a, href: href, c: Icons[t.uri] ? '' : (t.R.fragment||t.R.basename), class: Icons[t.uri]}}
             when Size
               l[Size].do{|sz|
                 sum = 0
                 sz.justArray.map{|v|
                   sum += v.to_i}
                 sum}
             when Creator
               [l[k].justArray.map{|v|
                 if v.respond_to? :uri
                   indexLink[v]
                 else
                   {_: :span, c: (CGI.escapeHTML v.to_s)}
                 end}.intersperse(' '),
                (l[SIOC+'user_agent'].do{|ua|
                   ['<br>', {_: :span, class: :notes, c: ua.join}]} unless head)]
             when SIOC+'addressed_to'
               l[k].justArray.map{|v|
                 if v.respond_to? :uri
                   indexLink[v]
                 else
                   {_: :span, c: (CGI.escapeHTML v.to_s)}
                 end}.intersperse(' ')
             when Date
               {_: :a, class: :date, href: datePath + '#r' + href.sha2, c: date} if datePath
             when DC+'cache'
               l[k].justArray.map{|c|[{_: :a, href: c.path, class: :chain}, ' ']}
             when DC+'link'
               linkTable[l[k].justArray]
             else
               l[k].justArray.map{|v|v.respond_to?(:uri) ? v.R : CGI.escapeHTML(v.to_s)}.intersperse(' ')
             end}}.intersperse("\n")}
    end
  }

  Search = -> graph,re {
    query = re.q['q'] || re.q['f']
    useGrep = re.path.split('/').size > 3 # select a default search-provider
    {class: :search,
     c: {_: :form,
         c: [{_: :a, class: :find, href: (query ? '?' : '') + '#searchbox' },
             {_: :input, id: :searchbox,
              name: useGrep ? 'q' : 'f',
              placeholder: useGrep ? :grep : :find
             }.update(query ? {value: query} : {})]}} unless re.path=='/'}

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