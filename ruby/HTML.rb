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
    pre,link,post = self.partition /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escaped URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escaped pre-match
      (link.empty? && '' || '<a href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # image RDF
        "<img src='#{u}'/>"      # inline image
       else
         if b #&& !u.match(/groups.google/)
           yield(R::DC+'link',u.R) # link RDF
           u.sub(/^https?.../,'')  # text
         else
           '' # skip URL
         end
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # recursion on post-match tail
  rescue Exception => x
    puts [x.class,x.message,self[0..127]].join(" ")
    ""
  end
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end

class R

  def nokogiri; require 'nokogiri'; Nokogiri::HTML.parse (open uri).read end
  def label; fragment || (path && basename != '/' && (URI.unescape basename)) || host || '' end
  def stripDoc; R[uri.sub /\.(e|html|json|log|md|msg|ttl|txt)$/,''].setEnv(@r) end
  def + u; R[uri + u.to_s].setEnv @r end
  def <=> c; to_s <=> c.to_s end
  def ==  u; to_s == u.to_s end

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove} if loseTags
    html.traverse{|e|
      e.attribute_nodes.map{|a|
        a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml(:indent => 0)}

  # tree-graph -> XML-in-Ruby -> HTML
  HTML = -> graph, re { e=re.env
    e[:title] = graph[re.path+'#this'].do{|r|r[Title].justArray[0]}
    re.path!='/' && !graph.empty? && re.q['q'].do{|q|Grep[graph,q]}
    br = '<br clear=all>'
    upPage = e[:Links][:up].do{|u|[{_: :a, c: '&#9650;', id: :Up, rel: :up, href: (CGI.escapeHTML u.to_s)},br]} unless re.path=='/'
    prevPage = e[:Links][:prev].do{|p|{_: :a, c: '&#9664;', rel: :prev, href: (CGI.escapeHTML p.to_s)}}
    nextPage = e[:Links][:next].do{|n|{_: :a, c: '&#9654;', rel: :next, href: (CGI.escapeHTML n.to_s)}}
    downPage = e[:Links][:down].do{|d|[br,{_: :a, c: '&#9660;', id: :Down, rel: :down, href: (CGI.escapeHTML d.to_s)}]}
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :title, c: e[:title]||re.path},
                 {_: :link, rel: :icon, href: '/.conf/icon.png'},
                 {_: :script, c: '.conf/site.js'.R.readFile},
                 {_: :style, c: '.conf/site.css'.R.readFile},
                 e[:Links].do{|links|links.map{|type,uri| {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                ]},
            {_: :body,
             c: [upPage, prevPage, nextPage, # page pointers
                 re.path[-1]=='/' && e[:overview].do{|o|
                   [OverView[graph,re,o],br]},
                 TabularView[graph,re], # resources
                 ([{_: :style, c: "body {text-align:center;background-color:##{'%06x' % (rand 16777216)}}"},
                   {_: :span,style: 'font-size:12em;font-weight:bold',c: 404}] if graph.empty?),
                 ([br,prevPage,nextPage] if graph.keys.size > 8), downPage]}]}]}

  InlineMeta = [Title, Image, Content, Label, DC+'hasFormat', DC+'link', SIOC+'attachment', SIOC+'user_agent', Stat+'contains']

  VerboseMeta = [DC+'identifier', DC+'source', DCe+'rights', DCe+'publisher',
                 RSS+'comments', RSS+'em', RSS+'category',
                 Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',
                 SIOC+'has_discussion', SIOC+'reply_of', SIOC+'num_replies', Mtime, Podcast+'explicit', Podcast+'summary',
                 "http://wellformedweb.org/CommentAPI/commentRss","http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content",Harvard+'featured']

  OverView = -> graph,env,style {
    case style
    when :year
      "years"
    else
    end
  }

  TabularView = -> g, e {
    e.env[:label] = {} # named labels
    (1..10).map{|i|e.env[:label]["quote"+i.to_s] = true} # colorize levels of quoting
    [:links,:images].map{|p| e.env[p] = []} # link/image lists to track duplicates
    p = e.q['sort'] || Date
    direction = e.q.has_key?('ascending') ? :id : :reverse
    datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
    keys = [Type,Creator,To,g.values.select{|v|v.respond_to? :keys}.map(&:keys)].flatten.uniq
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
             {_: :th,href: href,property: k,class: k==p ? 'selected' : '',c: {_: :a,href: href,class: Icons[k]||'',c: Icons[k] ? '' : (k.R.fragment||k.R.basename)}}}}]},
     {_: :style, c: e.env[:label].map{|name,_| "[name=\"#{name}\"] {color:#000;background-color: #{'#%06x' % (rand 16777216)}}\n"}},
     {_: :style, c: "[property=\"#{p}\"] {border-color:#999;border-style: solid; border-width: 0 0 .1em 0}"}]}

  TableRow = -> l,e,sort,direction,keys {
    #id 
    this = l.R
    href = this.uri
    head = e.q.has_key? 'head'
    rowID = if e.path == this.path && this.fragment
              this.fragment
            else
              'r' + href.sha2
            end
    focus = !this.fragment && this.path==e.path

    # type
    types = l.types
    isImg = types.member? Image
    isCode = types.member? SIOC+'SourceCode'
    isChat = types.member? SIOC+'InstantMessage'
    isMail = types.member? SIOC+'MailMessage'
    isBlog = types.member? SIOC+'BlogPost'
    monospace = isChat || isCode || isMail

    # date
    date = l[Date].justArray.sort[-1]
    datePath = '/' + date[0..13].gsub(/[-T:]/,'/') if date

    # name(s), required to show in header
    names = l[Title].justArray # explicit title
    if names.empty? && this.path # no explicit title found
      if isChat # individual msgs hidden in overview
      else # file and request-URI metadata
        fsName = (URI.unescape (File.basename this.path))[0..64] # fs name
        names.push(focus && e.env[:title] || fsName) # <req#this> title
      end
    end
    labels = l[Label].justArray
    this.host.do{|h|labels.unshift h}

    # pointer to resource as selection in result-set
    indexContext = -> p,v {
      v = v.R
      if isMail # address*month
        {_: :a, href: v.path + '?head#r' + href.sha2, c: v.label}
      elsif isBlog # host*day
        {_: :a, href: datePath[0..-4] + '*/*' + v.host + '*?head#r' + href.sha2, c: v.label}
      else
        v
      end}

    unless head && names.empty?
      {_: :tr, href: href, class: focus ? 'focus' : '',
       c: keys.map{|k|
         {_: :td, property: k,
          c: case k
             when 'uri'
               # names
               [names.map{|name|{_: :a, class: :title, href: href, c: (CGI.escapeHTML name.to_s)}}.intersperse(' '), ' ',
                # labels
                labels.map{|v|
                  label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                  lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                  e.env[:label][lbl] = true
                  [{_: :a, class: :label, href: href, name: lbl, c: (CGI.escapeHTML label)},' ']},
                # links
                (l[Stat+'contains'].justArray.sort_by(&:uri).do{|cs|{class: :containers, c: cs.map{|c|{_: :a, href: c.uri, c: c.label+' '}}} unless cs.empty?} unless focus),
                (links = [DC+'link',
                          SIOC+'attachment',
                          DC+'hasFormat'].map{|p|l[p]}.flatten.compact.map(&:R).select{|l|!e.env[:links].member? l} # unseen links
                 links.map{|l|e.env[:links].push l} # mark as visited
                 {_: :table, class: :links, # show
                  c: links.group_by(&:host).map{|host,links|
                    e.env[:label][host] = true
                    small = links.size < 5
                    {_: :tr,
                     c: [{_: :td, class: :host, c: ({_: :a, name: host, href: '//'+host, c: host.sub(/^www\./,'')} if host)},
                         {_: :td, class: :path, c: links.map{|link|
                            {_: :a, name: host, href: link.uri,
                                   c: CGI.escapeHTML(link.label[0..64])}.update(small ? {id: 'link_'+rand.to_s.sha2} : {})}.intersperse(' ')}]}}} unless links.empty?),
                (l[Content].justArray.map{|c|monospace ? {_: :pre,c: c} : [c,' ']} unless head),
                # images
                (images = [] # image list
                 images.push this if isImg       # subject of triple
                 l[Image].do{|i|images.concat i} #  object of triple
                 images.map(&:R).select{|i|!e.env[:images].member? i}.map{|img| # unseen images
                   e.env[:images].push img
                   {_: :a, class: :thumb, href: href,
                    c: {_: :img, src: if !img.host || e.host==img.host
                         img.path + '?thumb'
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
             end}}.intersperse("\n")}.update(focus ? {} : {id: rowID})
    end
  }

  # tree-graph grep result in HTML
  def R.tokens str; str ? str.scan(/[\w]+/).map(&:downcase).uniq : [] end
  Grep = -> graph, q {
    # tokenize
    wordIndex = {}
    words = R.tokens q
    words.each_with_index{|word,i|
      wordIndex[word] = i}
    # pattern expression
    pattern = /(#{words.join '|'})/i
    # match resources
    graph.map{|u,r|graph.delete u unless r.to_s.match pattern}
    # highlight matches
    graph.values.map{|r| # visit resource
      r[Content].justArray.map(&:lines).flatten.grep(pattern).do{|lines|
        r[Content] = lines[0..5].map{|line|
          line.gsub(/<[^>]+>/,'')[0..512].gsub(pattern){|g| # capture matches
            H({_: :span, class: "w#{wordIndex[g.downcase]}", c: g}) # render HTML
          }} if lines.size > 0
      }}
    # highlighting CSS
    graph['#grep.CSS'] = {Content => H({_: :style, c: wordIndex.values.map{|i|
      ".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}
    graph}

end
