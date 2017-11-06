# coding: utf-8
def H x # HTML generator
  case x
  when String
    x
  when Hash # element
    void = [:img, :input, :link, :meta].member? x[:_]
    '<' + (x[:_] || 'div').to_s +                        # element name
      (x.keys - [:_,:c]).map{|a|                         # attribute name
      ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
        {"'"=>'%27', '>'=>'%3E',
         '<'=>'%3C'}[c]||c}.join + "'"}.join +
      (void ? '/' : '') + '>' + (H x[:c]) +              # children
      (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # element closer
  when Array # sequential structure
    x.map{|n|H n}.join
  when R # <a>
    H({_: :a, href: x.uri, c: x.label})
  when NilClass
    ''
  when FalseClass
    ''
  else
    CGI.escapeHTML x.to_s
  end
end

class Hash
  def types; self[R::Type].justArray.select{|t|t.respond_to? :uri}.map &:uri end
end

class Array
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
end

class String
  def R; R.new self end
  # scan for HTTP URIs in string. example:
  # demo on the site (https://demohere) and source-code at https://sourcehere.
  # [,.] only match mid-URI, opening ( required for ) capture, <> wrapping is stripped
  def hrefs &b
    pre,link,post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escaped URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escaped pre-match
      (link.empty? && '' || '<a href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # image RDF
        "<img src='#{u}'/>"      # inline image
       else
         yield(R::DC+'link',u.R) if b # link RDF
         u.sub(/^https?.../,'')  # inline text
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # recursion on post-capture tail
  end
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end

class R
  View = {}

  ViewConfig = {
    epoch: {
      type: :epoch,
      childType: :year,
      path: /^\/$/,
      size: 1},
    year: {
      type: :year,
      childType: :month,
      path: /^\/\d{4}\/$/,
      size: 12},
    month: {
      type: :month,
      childType: :day,
      path: /^\/\d{4}\/\d{2}\/$/,
      size: 30},
    day: {
      type: :day,
      childType: :hour,
      path: /^\/\d{4}\/\d{2}\/\d{2}\/$/,
      size: 24},
    hour: {
      type: :hour,
      path: /^\/\d{4}\/\d{2}\/\d{2}\/\d{2}\/$/,
      size: 3600}}

  InlineMeta = [Title, Image, Abstract, Content, Label, DC+'hasFormat', DC+'link', SIOC+'attachment', SIOC+'user_agent', Stat+'contains']

  VerboseMeta = [DC+'identifier', DC+'source', DCe+'rights', DCe+'publisher', RSS+'comments', RSS+'em', RSS+'category', Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate', SIOC+'has_discussion', SIOC+'reply_of', SIOC+'num_replies', Mtime, Podcast+'explicit', Podcast+'summary', "http://wellformedweb.org/CommentAPI/commentRss","http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content",Harvard+'featured']

  def R.tokens str; str ? str.scan(/[\w]+/).map(&:downcase).uniq : [] end

  def nokogiri; Nokogiri::HTML.parse (open uri).read end

  Grep = -> graph, q {
    wordIndex = {}
    words = R.tokens q
    words.each_with_index{|word,i|
      wordIndex[word] = i}
    pattern = /(#{words.join '|'})/i
    # drop non-matching resources
    graph.map{|u,r|graph.delete u unless r.to_s.match pattern}
    # highlight matches
    graph.values.map{|r|
      r[Content].justArray.map(&:lines).flatten.grep(pattern).do{|lines|
        r[Abstract] = [lines[0..5].map{|l|
          l.gsub(/<[^>]+>/,'')[0..512].gsub(pattern){|g| # capture match
            H({_: :span, class: "w#{wordIndex[g.downcase]}", c: g}) # wrapper span
          }},{_: :hr}] if lines.size > 0 }}
    graph['#abstracts'] = {Abstract => {_: :style, c: wordIndex.values.map{|i|".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}}}
    graph}

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove} if loseTags
    html.traverse{|e|
      e.attribute_nodes.map{|a|
        a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml(:indent => 0)}

  HTML = -> graph, re {
    e = re.env
    e[:title] = graph[re.path+'#this'].do{|r|r[Title].justArray[0]}
    if q = re.q['q']
      Grep[graph,q]
    end
    expand = e[:Links][:down].do{|d|{_: :a, id: :down, c: '&#9660;', href: (CGI.escapeHTML d.to_s)}}
    foot = [{_: :style, c: "body {text-align:center;background-color:##{'%06x' % (rand 16777216)}}"}, {_: :span,style: 'font-size:12em;font-weight:bold',c: 404}, (CGI.escapeHTML e['HTTP_USER_AGENT'])] if graph.empty?
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'}, {_: :title, c: e[:title]||re.path}, {_: :link, rel: :icon, href: '/.conf/icon.png'},
                 %w{code icons site}.map{|s|{_: :style, c: ".conf/#{s}.css".R.readFile}},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 {_: :script, c: '.conf/site.js'.R.readFile}]},
            {_: :body,
             c: [Nav[graph,re], Table[graph,re], expand, foot]}]}]}

  Nav = -> graph,re {
    env = re.env; path = "" ; depth = 0
    config = ViewConfig[env[:view]] || {}
    grep = [:day,:hour].member? config[:type]
    query = re.q['q'] || re.q['f']
    childType = config[:childType]
    if childType
      c = ViewConfig[childType]
      childSize = c[:size]
      childPath = c[:path]
      children = graph.values.select{|r|r.R.path.do{|p|p.match childPath}}.sort_by &:uri
      showChildren = children.size > 1
      max = children.map{|c|c[Size].justArray[0]||0}.max.to_f
    end
    color = '#%06x' % (rand 16777216)
    prevRange = env[:Links][:prev].do{|p|{_: :a, id: :prev, c: '&#9664;', href: (CGI.escapeHTML p.to_s)}}
    nextRange = env[:Links][:next].do{|n|{_: :a, id: :next, c: '&#9654;', href: (CGI.escapeHTML n.to_s)}}
    [{class: :nav,
      c: [prevRange,
          (re.path.split '/').map{|part|
            path = path + part + '/'
            depth += 1
            {_: :a, id: 'p'+path.sha2, class: :pathPart, style: depth > 4 ? 'font-weight: normal' : '', href: path + '?head', c: [CGI.escapeHTML(URI.unescape part),{_: :span, class: :sep, c: '/'}]}},
          {_: :a, class: :clock, href: '/h', id: :uptothetime},
          ({_: :form,
            c: [{_: :a, class: :find, href: (query ? '?' : '') + '#searchbox' },
                {_: :input, id: :searchbox,
                 name: grep ? 'q' : 'f', # FIND big dirs GREP small dirs
                 placeholder: grep ? :grep : :find
                }.update(query ? {value: query} : {})]} unless re.path=='/'),
          nextRange]},
     ({_: :table, class: :dir,
      c: [{_: :tr, c: children.map{|r|
            size = r[Size].justArray[0]||0
            full = env[:du] ? false : (size >= childSize)
            {_: :td, class: :dir,
             c: {_: :a, href: r.uri + '?head',
                 id: childType.to_s + r.R.basename,
                 style: size ? "background-color:#{full ? '#eee' : color}; height:#{100.0 * size / max}%" : '',
                 c: r.R.basename}}}},
          {_: :tr, c: children.map{|r|
             graph.delete r.uri
             {_: :td, class: :subdir,
              c: r[Stat+'contains'].justArray.sort_by(&:uri).map{|c|
                nom = c.R.basename[0..63]
                {_: :a, href: c.uri, style: "background-color:##{('%02x' % (255-nom.size*4))*3}",
                 c: CGI.escapeHTML(URI.unescape nom)}.update(nom.to_i%6 == 0 ? {id: 'h'+rand.to_s.sha2} : {})}}}}]} if showChildren)]}

  Table = -> g, e {
    # labels
    e.env[:label] = {}
    (1..10).map{|i|e.env[:label]["quote"+i.to_s] = true}
    [:links,:images].map{|p| e.env[p] = []} # link & image lists
    # sort configuration
    p = e.q['sort'] || Date
    direction = e.q.has_key?('ascending') ? :id : :reverse
    datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
    keys = [Creator,To,Type,g.values.select{|v|v.respond_to? :keys}.map(&:keys)].flatten.uniq
    keys -= InlineMeta; keys -= VerboseMeta unless e.q.has_key? 'full'
    [{_: :table,
      c: [{_: :tbody,
           c: g.values.sort_by{|s|((p=='uri' ? (s[Title]||s[Label]||s.uri) : s[p]).justArray[0]||0).send datatype}.send(direction).map{|r|
             TableRow[r,e,p,direction,keys]}.intersperse("\n")},
          {_: :tr, c: keys.map{|k| # header row
             q = e.q.merge({'sort' => k})
             if direction == :id # direction toggle
               q.delete 'ascending'
             else
               q['ascending'] = ''
             end
             href = CGI.escapeHTML R.qs q
             {_: :th, id: 'sort_'+k.sha2, href: href,property: k,class: k==p ? 'selected' : '',c: {_: :a,href: href,class: Icons[k]||'',c: Icons[k] ? '' : (k.R.fragment||k.R.basename)}}}}]},
     {_: :style, c: e.env[:label].map{|name,_| "[name=\"#{name}\"] {color:#000;background-color: #{'#%06x' % (rand 16777216)}}\n"}},
     {_: :style, c: "[property=\"#{p}\"] {border-color:#444;border-style: solid; border-width: 0 0 .08em 0}"}]}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    href = this.uri
    head = e.q.has_key? 'head'
    rowID = (e.path == this.path && this.fragment) ? this.fragment : 'r'+href.sha2
    focus = !this.fragment && this.path==e.path
    types = l.types
    chatMsg = types.member? SIOC+'InstantMessage'
    mailMsg = types.member? SIOC+'MailMessage'
    monospace = chatMsg || mailMsg || types.member?(SIOC+'SourceCode')
    date = l[Date].justArray.sort[-1]
    datePath = '/' + date[0..13].gsub(/[-T:]/,'/') if date
    titles = l[Title].justArray # explicit title
    if titles.empty? && this.path
      if chatMsg # don't elevate filename as implicit title, for these types
      else
        fsName = (URI.unescape (File.basename this.path))[0..64] # filename, default title if none other found
        titles.push(focus && e.env[:title] || fsName) # requestURI title from environment
      end
    end
    labels = l[Label].justArray
    this.host.do{|h|labels.unshift h}
    # generate pointer to resource as selection in index
    indexContext = -> p,v {
      v = v.R
      if mailMsg # address*month
        {_: :a, href: v.path + '?head#r' + href.sha2, c: v.label}
      elsif types.member? SIOC+'BlogPost' # host*day
        {_: :a, href: datePath[0..-4] + '*/*' + (v.host||'') + '*?head#r' + href.sha2, c: v.label}
      else
        v
      end}
    unless head && titles.empty? && !l[Abstract]
      {_: :tr, id: rowID, href: href + (!this.host && href[-1]=='/' && '?head' || ''), class: focus ? 'focus' : '',
       c: keys.map{|k|
         {_: :td, property: k,
          c: case k
             when 'uri'
               [labels.map{|v|
                  label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                  lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                  e.env[:label][lbl] = true
                  [{_: :a, class: :label, href: href, name: lbl, c: (CGI.escapeHTML label[0..41])},' ']},
                titles.map{|t|[{_: :a, class: :title, href: href, c: (CGI.escapeHTML t.to_s)},'<br>']},
                (l[Stat+'contains'].justArray.sort_by(&:uri).do{|cs|{_: :span, class: :children, c: cs.map{|c|[{_: :a, id: 'child'+c.uri.sha2, href: c.uri + (c.host ? '' : '?head'), c: c.label}, ' ']}} unless cs.empty?} unless focus),
                (links = [DC+'link', SIOC+'attachment'].map{|p|l[p]}.flatten.compact.map(&:R).select{|l|!e.env[:links].member? l} # unseen links
                 links.map{|l|e.env[:links].push l} # mark as displayed
                 {_: :table, class: :links,
                  c: links.group_by(&:host).map{|host,links|
                    {_: :tr,
                     c: [{_: :td, class: :host, c: ({_: :a, href: '//'+host, c: host} if host)},
                         {_: :td, class: :path, c: links.map{|link|
                            [{_: :a, id: 'link_'+rand.to_s.sha2, href: link.uri, c: CGI.escapeHTML(URI.unescape(link.path||'/')[0..64])},' ']}}]}}} unless links.empty?),
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
                   indexContext[k,v]
                 else
                   CGI.escapeHTML v.to_s
                 end}.intersperse(' '),
                (l[SIOC+'user_agent'].do{|ua|
                   ['<br>', {_: :span, class: :notes, c: ua.join}]} unless head)]
             when SIOC+'addressed_to'
               l[k].justArray.map{|v|
                 if v.respond_to? :uri
                   indexContext[k,v]
                 else
                   CGI.escapeHTML v.to_s
                 end}.intersperse(' ')
             when Date
               {_: :a, class: :date, href: (datePath||'') + '#r' + href.sha2, c: date}
             when DC+'cache'
               l[k].justArray.map{|c|[{_: :a, href: c.path, class: :chain}, ' ']}
             else
               l[k].justArray.map{|v|v.respond_to?(:uri) ? v.R : CGI.escapeHTML(v.to_s)}.intersperse(' ')
             end}}.intersperse("\n")}
    end
  }

end
