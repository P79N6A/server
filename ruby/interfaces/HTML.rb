# coding: utf-8
class WebResource

  module HTML
    include URIs
    InlineMeta = [Title, Image, Abstract, Content, Label, DC+'link', Atom+'link', RSS+'link', RSS+'guid', DC+'hasFormat', SIOC+'channel', SIOC+'attachment', SIOC+'user_agent', Stat+'contains']
    VerboseMeta = [DC+'identifier', DC+'source', DCe+'rights', DCe+'publisher',
                   RSS+'comments', RSS+'em', RSS+'category', Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',
                   SIOC+'has_discussion', SIOC+'reply_of', SIOC+'num_replies', Mtime, Podcast+'explicit', Podcast+'summary', Comments,"http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content"]
    LinkPred = [SIOC+'attachment',Stat+'contains',Atom+'link',RSS+'link',DC+'link']

      Icons = {
      'uri' => :id,
      Type => :type,
      Container => :dir,
      Content => :pencil,
      Date => :date,
      Label => :tag,
      Title => :title,
      Sound => :speaker,
      Image => :img,
      Size => :size,
      Mtime => :time,
      To => :userB,
      DC+'hasFormat' => :file,
      DC+'link' => :chain,
      DC+'cache' => :chain,
      Schema+'Person' => :user,
      Schema+'location' => :location,
      RSS+'comments' => :comments,
      Comments => :comments,
      Stat+'File' => :file,
      Stat+'Archive' => :archive,
      Stat+'HTMLFile' => :html,
      Stat+'WordDocument' => :word,
      Stat+'DataFile' => :tree,
      Stat+'TextFile' => :textfile,
      Stat+'width' => :width,
      Stat+'height' => :height,
      Stat+'container' => :dir,
      Stat+'contains' => :dir,
      SIOC+'BlogPost' => :pencil,
      SIOC+'ChatLog' => :comments,
      SIOC+'Discussion' => :comments,
      SIOC+'Feed' => :feed,
      SIOC+'InstantMessage' => :comment,
      SIOC+'MicroblogPost' => :newspaper,
      SIOC+'WikiArticle' => :pencil,
      SIOC+'Usergroup' => :group,
      SIOC+'SourceCode' => :code,
      SIOC+'Tweet' => :bird,
      SIOC+'has_creator' => :user,
      SIOC+'user_agent' => :mailer,
      SIOC+'has_discussion' => :comments,
      SIOC+'Thread' => :openenvelope,
      SIOC+'Post' => :newspaper,
      SIOC+'MailMessage' => :envelope,
      W3+'2000/01/rdf-schema#Resource' => :node,
    }

    def self.strip body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type}
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove} if loseTags
      html.traverse{|e|
        e.attribute_nodes.map{|a|
          a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml(:indent => 0)
    end

    def renderHTML graph
      empty = graph.empty?
      @r ||= {}
      @r[:title] ||= graph[path+'#this'].do{|r|r[Title].justArray[0]}
      @r[:label] ||= {}
      @r[:Links] ||= {}
      query = q['q']
      htmlGrep graph, query if query
      H ["<!DOCTYPE html>\n",
         {_: :html,
          c: [{_: :head,
               c: [{_: :meta, charset: 'utf-8'}, {_: :title, c: @r[:title]||path}, {_: :link, rel: :icon, href: '/.conf/icon.png'},
                   %w{code icons site}.map{|s|{_: :style, c: ".conf/#{s}.css".R.readFile}},
                   @r[:Links].do{|links|
                     links.map{|type,uri|
                       {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}
                     }},
                   {_: :script, c: '.conf/site.js'.R.readFile}]},
              {_: :body,
               c: [@r[:Links][:up].do{|p|
                     {_: :a, id: :up, c: '&#9650;', href: (CGI.escapeHTML p.to_s)}},
                   @r[:Links][:prev].do{|p|
                     {_: :a, id: :prev, c: '&#9664;', href: (CGI.escapeHTML p.to_s)}},
                   htmlSearch,
                   {class: :scroll, c: (htmlTree graph)},
                   !empty && (htmlTable graph),
                   {_: :style, c: @r[:label].map{|name,_|
                      color = '#%06x' % (rand 16777216)
                      "[name=\"#{name}\"] {color:#000; background-color: #{color}}\n"}},
                   !empty && @r[:Links][:down].do{|d|
                     {_: :a, id: :down, c: '&#9660;', href: (CGI.escapeHTML d.to_s)}},
                   empty && {_: :a, id: :nope, class: :notfound, style: "background-color:#{'#%06x' % (rand 16777216)}", c: '404'+'<br>'*7, href: dirname},
                   @r[:Links][:next].do{|n|
                     {_: :a, id: :next, c: '&#9654;', href: (CGI.escapeHTML n.to_s)}}]}]}]
    end

    def htmlTree graph
      # construct tree
      tree = {}
      graph.keys.select{|k|!k.R.host && k[-1]=='/'}.map{|uri|
        c = tree
        uri.R.parts.map{|name| # path instructions
          c = c[name] ||= {}}} # create node and jump cursor

      # renderer function
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
        # render
        {_: tabled ? :table : :div, class: :tree, border: 1, c: [
           {_: tabled ? :tr : :div, class: :nodes, c: nodes.map{|name| # nodes
              this = path + name + '/' # path
              s = graph[this].do{|r|r[Size].justArray[0]} # size
              graph.delete this # consume node
              named = !name.empty?
              scaled = size > 0 && s && tabled
              width = scaled && (s / size) # scale
              {_: tabled ? :td : :div,
               class: named ? (scaled ? :scaled : :unscaled) : '',
               style: scaled ? "width:#{width * 100.0}%" : '',
               c: named ? {_: :a, href: this + qs, name: label, id: 't'+this.sha2,
                           c: (scaled ? '' : ('&nbsp;'*path.size)) + CGI.escapeHTML(URI.unescape name) + (scaled ? '' : '/')} : ''}}.intersperse("\n")},"\n",
           {_: tabled ? :tr : :div, c: nodes.map{|k| # children
              {_: tabled ? :td : :div, c: (render[t[k], path+k+'/'] if t[k].size > 0)}}.intersperse("\n")}]}}

      # render tree
      render[tree]
    end

    def htmlTable graph
      (1..10).map{|i|@r[:label]["quote"+i.to_s] = true} # labels
      [:links,:images].map{|p|@r[p] = []} # link & image lists
      p = q['sort'] || Date
      direction = q.has_key?('ascending') ? :id : :reverse
      datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
      keys = graph.values.map(&:keys).flatten.uniq - InlineMeta
      keys -= VerboseMeta unless q.has_key? 'full'
      [{_: :table, style: 'margin:auto',
        c: [{_: :tbody,
             c: graph.values.sort_by{|s|((p=='uri' ? (s[Title]||s[Label]||s.uri) : s[p]).justArray[0]||0).send datatype}.send(direction).map{|r|
               (htmlTableRow r,p,direction,keys)}.intersperse("\n")},
            {_: :tr, c: keys.map{|k| # header row
               selection = p == k
               q_ = q.merge({'sort' => k})
               if direction == :id # direction toggle
                 q_.delete 'ascending'
               else
                 q_['ascending'] = ''
               end
               href = CGI.escapeHTML HTTP.qs q_
               {_: :th, property: k, class: selection ? 'selected' : '',
                c: [{_: :a,href: href,class: Icons[k]||'',c: Icons[k] ? '' : (k.R.fragment||k.R.basename)},
                    (selection ? {_: :link, rel: :sort, href: href} : '')]}}}]},
       {_: :style, c: "[property=\"#{p}\"] {border-color:#444;border-style: solid; border-width: 0 0 .08em 0}"}]
    end

    def htmlTableRow l,sort,direction,keys
      this = l.R
      inDoc = path == this.path
      reqURI = inDoc && !this.fragment
      identified = false
      href = this.uri
      head = q.has_key? 'head'
      types = l.types
      chat = types.member? SIOC+'InstantMessage'
      mail = types.member? SIOC+'MailMessage'
      post = types.member? SIOC+'BlogPost'
      tweet = types.member? SIOC+'Tweet'
      monospace = chat || mail || types.member?(SIOC+'SourceCode')
      date = l[Date].justArray.sort[0]
      datePath = '/' + date[0..13].gsub(/[-T:]/,'/') if date
      titles = l[Title].justArray

      linkTable = -> links {
        links = links.map(&:R).select{|l|!@r[:links].member? l}.sort_by &:tld
        {_: :table, class: :links,
         c: links.group_by(&:host).map{|host,links|
           tld = links[0] && links[0].tld || 'none'
           traverse = links.size <= 3
           @r[:label][tld] = true
           {_: :tr,
            c: [({_: :td, class: :host, name: tld,
                  c: {_: :a, href: '//'+host, c: host}} if host),
                {_: :td, class: :path, colspan: host ? 1 : 2,
                 c: links.map{|link| @r[:links].push link
                   [{_: :a, href: link.uri, c: CGI.escapeHTML(URI.unescape((link.host ? link.path : link.basename)||''))}.update(traverse ? {id: 'link'+rand.to_s.sha2} : {}),
                    ' ']}}]}}} unless links.empty? }

      rowID = -> {
        if identified || reqURI
          {}
        else
          identified = true
          {id: (inDoc && this.fragment) ? this.fragment : 'r'+href.sha2}
        end}

      # pointer to selection of node in an index context
      indexLink = -> v {
        v = v.R
        id = rand.to_s.sha2
        if mail # messages*month
          {_: :a, id: 'address_'+id, href: v.path + '?head#r' + href.sha2, c: v.label}
        elsif tweet # tweets*hour
          {_: :a, id: 'tweets_'+id, href: datePath + '*twitter*#r' + href.sha2, c: v.label}
        elsif post
          url = if datePath # host*month
                  datePath[0..-4] + '*/*' + (v.host||'') + '*#r' + href.sha2
                else
                  v.host
                end
          {_: :a, id: 'post_'+id, href: url, c: v.label}
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
                 [titles.compact.map{|t|
                    @r[:label][this.tld] = true
                    {_: :a, class: :title, href: link, name: this.tld,
                     c: (CGI.escapeHTML t.to_s)}.update(rowID[]).update(reqURI ? {class: :reqURI} : {})}.intersperse(' '),
                  l[Label].justArray.compact.map{|v|
                    label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                    lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                    @r[:label][lbl] = true
                    {_: :a, class: :label, href: link, name: lbl, c: ' '+(CGI.escapeHTML label[0..41])}.update(rowID[])},
                  linkTable[LinkPred.map{|p|l[p]}.flatten.compact],
                  l[Abstract].do{|abs|{_: :pre, c: abs}},
                  (l[Content].justArray.map{|c|monospace ? {_: :pre,c: c} : [c,' ']} unless head),
                  (images = []
                   images.push this if types.member?(Image) # subject of triple
                   l[Image].do{|i|images.concat i}          # object of triple
                   images.map(&:R).select{|i|!@r[:images].member? i}.map{|img| # unseen images
                     @r[:images].push img # seen
                     {_: :a, class: :thumb, href: href,
                      c: {_: :img, src: if !img.host || host==img.host
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
                 l[k].justArray.map{|c|[{_: :a, href: c.R.path, class: :chain}, ' ']}
               else
                 l[k].justArray.map{|v|v.respond_to?(:uri) ? v.R : CGI.escapeHTML(v.to_s)}.intersperse(' ')
               end}}.intersperse("\n")}
      end
    end

    def htmlGrep graph, q
      wordIndex = {}
      args = q.shellsplit
      args.each_with_index{|arg,i| wordIndex[arg] = i }
      pattern = /(#{args.join '|'})/i
      # find matches
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
      # word-highlight CSS
      graph['#abstracts'] = {Abstract => {_: :style, c: wordIndex.values.map{|i|".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}}}
    end

    def htmlSearch
      query = q['q'] || q['f']
      useGrep = path.split('/').size > 3 # search-provider suggestion
      {class: :search,
       c: {_: :form,
           c: [{_: :a, class: :find, href: (query ? '?' : '') + '#searchbox' },
               {_: :input, id: :searchbox,
                name: useGrep ? 'q' : 'f',
                placeholder: useGrep ? :grep : :find
               }.update(query ? {value: query} : {})]}} unless path=='/'
    end

    def nokogiri
      Nokogiri::HTML.parse (open uri).read
    end

  end
  module Webize
    def triplrHTML &f
      triplrFile &f
      yield uri, Type, R[Stat+'HTMLFile']
      n = Nokogiri::HTML.parse readFile
      n.css('title').map{|title| yield uri, Title, title.inner_text }
      n.css('meta[property="og:image"]').map{|m| yield uri, Image, m.attr("content").R }
    end
    
    def triplrMarkdown
      doc = stripDoc.uri
      yield doc, Type, R[Stat+'TextFile']
      yield doc, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile)
      mtime.do{|mt|yield doc, Date, mt.iso8601}
    end
  end
end

class String
  def R; WebResource.new self end
  # scan for HTTP URIs in string
  # opening '(' required for ')' capture, <> wrapping stripped, ',' and '.' only match mid-URI:
  # demo on the site (https://demohere) and source-code at https://sourcehere.
  def hrefs &b
    pre,link,post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escaped URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escaped pre-match
      (link.empty? && '' || '<a class=scanned href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # image RDF
        "<img src='#{u}'/>"      # inline image
       else
         yield(R::DC+'link',u.R) if b # link RDF
         u.sub(/^https?.../,'')  # inline text
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # tail
  end
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end

module Redcarpet
  module Render
    class Pygment < HTML
      def block_code(code, lang)
        if lang
          IO.popen("pygmentize -l #{lang.downcase.sh} -f html",'r+'){|p|
            p.puts code
            p.close_write
            p.read
          }
        else
          code
        end
      end
    end
  end
end

def H x # HTML from ruby values
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
  when Array # structure
    x.map{|n|H n}.join
  when R
    H({_: :a, href: x.uri, c: x.label})
  when NilClass
    ''
  when FalseClass
    ''
  else
    CGI.escapeHTML x.to_s
  end
end
