# coding: utf-8
class WebResource
  module HTML
    def self.render x
      case x
      when String
        x
      when Hash
        void = [:img, :input, :link, :meta].member? x[:_]
        '<' + (x[:_] || 'div').to_s +                        # element name
          (x.keys - [:_,:c]).map{|a|                         # attribute name
          ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
            {"'"=>'%27', '>'=>'%3E',
             '<'=>'%3C'}[c]||c}.join + "'"}.join +
          (void ? '/' : '') + '>' + (render x[:c]) +              # children
          (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # element closer
      when Array
        x.map{|n|render n}.join
      when R
        render({_: :a, href: x.uri, c: x.label})
      when NilClass
        ''
      when FalseClass
        ''
      else
        CGI.escapeHTML x.to_s
      end
    end
    include URIs
    InlineMeta = [Title, Image, Abstract, Content, Label, DC+'link', DC+'note', Atom+'link', RSS+'link', RSS+'guid', DC+'hasFormat', SIOC+'channel', SIOC+'attachment', SIOC+'user_agent', Stat+'contains']
    VerboseMeta = [DC+'identifier', DC+'source', DCe+'rights', DCe+'publisher',RSS+'comments', RSS+'em', RSS+'category', Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate', SIOC+'has_discussion', SIOC+'reply_of', SIOC+'num_replies', Mtime, Podcast+'explicit', Podcast+'summary', Comments,"http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content"]
    LinkPred = [SIOC+'attachment',Stat+'contains',Atom+'link',RSS+'link',DC+'link']

    def self.strip body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type}
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove} if loseTags
      html.traverse{|e|
        e.attribute_nodes.map{|a|
          a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml(:indent => 0)
    end

    def htmlDocument graph = {}
      empty = graph.empty?
      @r ||= {}
      @r[:title] ||= graph[path+'#this'].do{|r|r[Title].justArray[0]}
      @r[:label] ||= {}
      @r[:Links] ||= {}
      htmlGrep graph, q['q'] if q['q']
      query = q['q'] || q['f']
      useGrep = path.split('/').size > 3 # search-provider suggestion
      link = -> name,icon {
        @r[:Links][name].do{|href|
          {_: :a, id: name, c: icon, href: (CGI.escapeHTML href.to_s)}}}

      HTML.render ["<!DOCTYPE html>\n",
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
                         c: [link[:up, '&#9650;'], link[:prev, '&#9664;'], link[:next, '&#9654;'],
                             path!='/' && {class: :search,
                                           c: {_: :form,
                                               c: [{_: :a, id: :query, class: :find, href: (query ? '?head' : '') + '#searchbox' },
                                                   {_: :input, id: :searchbox, name: useGrep ? 'q' : 'f',
                                                    placeholder: useGrep ? :grep : :find
                                                   }.update(query ? {value: query} : {})]}},
                             {class: :scroll, c: (htmlTree graph)},
                             !empty && (htmlTable graph),
                             {_: :style, c: @r[:label].map{|name,_|
                                color = '#%06x' % (rand 16777216)
                                "[name=\"#{name}\"] {color:#000; background-color: #{color}}\n"}},
                             !empty && @r[:Links][:down].do{|d|
                               {_: :a, id: :down, c: '&#9660;', href: (CGI.escapeHTML d.to_s)}},
                             empty && {_: :a, id: :nope, class: :notfound, style: "background-color:#{'#%06x' % (rand 16777216)}", c: '404'+'<br>'*7, href: dirname}]}]}]
    end

    def htmlTree graph
      q = qs.empty? ? '?head' : qs
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
        # output
        {_: tabled ? :table : :div, class: :tree, border: 1, c: [
           {_: tabled ? :tr : :div, class: :nodes, c: nodes.map{|name| # nodes
              this = path + name + '/' # path
              s = graph[this].do{|r|r[Size].justArray[0]} # size
              named = !name.empty?
              scaled = size > 0 && s && tabled
              width = scaled && (s / size) # scale
              {_: tabled ? :td : :div,
               class: named ? (scaled ? :scaled : :unscaled) : '',
               style: scaled ? "width:#{width * 100.0}%" : '',
               c: named ? {_: :a, href: this + q, name: label, id: 't'+this.sha2,
                           c: (scaled ? '' : ('&nbsp;'*path.size)) + CGI.escapeHTML(URI.unescape name) + (scaled ? '' : '/')} : ''}}.intersperse("\n")},"\n",
           ({_: tabled ? :tr : :div, c: nodes.map{|k| # children
              {_: tabled ? :td : :div, c: (render[t[k], path+k+'/'] if t[k].size > 0)}}.intersperse("\n")} unless !nodes.find{|n|t[n].size > 0})]}}

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
      [{_: :table, border: 1, style: 'margin:auto;border: .0em solid black',
        c: [{_: :tbody,
             c: graph.values.sort_by{|s|((p=='uri' ? (s[Title]||s[Label]||s.uri) : s[p]).justArray[0]||0).send datatype}.send(direction).map{|r|
               (r.R.environment(@r).htmlTableRow p,direction,keys)}.intersperse("\n")},
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

    def htmlTableRow sort,direction,keys
      inDoc = path == @r['REQUEST_PATH']
      identified = false
      date = self[Date].sort[0]
      datePath = '/' + date[0..13].gsub(/[-T:]/,'/') if date

      linkTable = -> links {
        links = links.map(&:R).select{|l|!@r[:links].member? l}.sort_by &:tld
        {_: :table, class: :links,
         c: links.group_by(&:host).map{|host,links|
           tld = links[0] && links[0].tld || 'none'
           traverse = links.size <= 16
           @r[:label][tld] = true
           {_: :tr,
            c: [({_: :td, class: :host, name: tld,
                  c: {_: :a, href: '//'+host, c: host}} if host),
                {_: :td, class: :path, colspan: host ? 1 : 2,
                 c: links.map{|link| @r[:links].push link
                   [{_: :a, href: link.uri, c: CGI.escapeHTML(URI.unescape((link.host ? link.path : link.basename)||''))}.update(traverse ? {id: 'link'+rand.to_s.sha2} : {}),
                    ' ']}}]}}} unless links.empty? }

      # From/To fields in one column
      ft = false
      fromTo = -> {
        unless ft
          ft = true
          [[Creator,SIOC+'addressed_to'].map{|edge|
             self[edge].map{|v|
               if v.respond_to? :uri
                 v = v.R
                 id = rand.to_s.sha2
                 # domain-specific index-location pointer
                 if a SIOC+'MailMessage' # messages*address*month
                   {_: :a, id: 'address_'+id, href: v.path + '?head#r' + sha2, c: v.label}
                 elsif a SIOC+'Tweet'
                   if edge == Creator  # tweets*author*day
                     {_: :a, id: 'tw'+id, href: datePath[0..-4] + '*/*twitter.com.'+v.basename+'*#r' + sha2, c: v.label}
                   else # tweets*hour
                     {_: :a, id: 'tw'+id, href: datePath + '*twitter*#r' + sha2, c: v.label}
                   end
                 elsif a SIOC+'BlogPost'
                   url = if datePath # posts*host*day
                           datePath[0..-4] + '*/*' + (v.host||'') + '*#r' + sha2
                         else
                           v.host
                         end
                   {_: :a, id: 'post_'+id, href: url, c: v.label}
                 else
                   v
                 end
               else
                 {_: :span, c: (CGI.escapeHTML v.to_s)}
               end}.intersperse(' ')}.map{|a|a.empty? ? nil : a}.compact.intersperse('&rarr;'),
           self[SIOC+'user_agent'].map{|a|['<br>',{_: :span, class: :notes, c: a}]}]
        end}

      unless q.has_key?('head') && self[Title].empty? && self[Abstract].empty? # title or abstract required in heading-mode
        {_: :tr,
         c: keys.map{|k|
           {_: :td, property: k,
            c: case k
               when 'uri'
                 [self[Label].compact.map{|v|
                    {_: :a, class: a(SIOC+'Tweet') ? :twitter : :label, href: uri, c: (CGI.escapeHTML (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v))}}.intersperse(' '),
                  self[Title].compact.map{|t|
                    @r[:label][tld] = true
                    {_: :a, class: :title, href: uri, name: inDoc ? :localhost : tld,
                     c: (CGI.escapeHTML t.to_s)}.update(if identified || (inDoc && !fragment)
                                                        {}
                                                       else
                                                         identified = true # doc-local identifier
                                                         {id: (inDoc && fragment) ? fragment : 'r'+sha2, primary: :true}
                                                        end)}.intersperse(' '),
                  self[Abstract], linkTable[LinkPred.map{|p|self[p]}.flatten.compact],
                  (self[Content].map{|c|
                     if (a SIOC+'SourceCode') || (a SIOC+'MailMessage')
                       {_: :pre, c: c}
                     elsif a SIOC+'InstantMessage'
                       {_: :span, class: :monospace, c: c}
                     else
                       c
                     end
                   }.intersperse(' ') unless q.has_key?('head')),
                  (images = []
                   images.push self if types.member?(Image) # is subject of triple
                   self[Image].do{|i|images.concat i}      # is object of triple
                   images.map(&:R).select{|i|!@r[:images].member? i}.map{|img| # unseen images
                     @r[:images].push img # seen
                     {_: :a, class: :thumb, href: uri,
                      c: {_: :img, src: if !img.host || host==img.host
                           img.path + '?preview'
                         else
                           img.uri
                          end}}})].intersperse(' ')
               when Type
                 self[Type].uniq.select{|t|t.respond_to? :uri}.map{|t|
                   {_: :a, href: uri, c: Icons[t.uri] ? '' : (t.R.fragment||t.R.basename), class: Icons[t.uri]}}
               when Size
                 sum = 0
                 self[Size].map{|v|sum += v.to_i}
                 sum == 0 ? '' : sum
               when Creator
                 fromTo[]
               when SIOC+'addressed_to'
                 fromTo[]
               when Date
                 [({_: :a, class: :date, href: datePath + '#r' + sha2, c: date} if datePath),
                  self[DC+'note'].map{|n|{_: :span, class: :notes, c: n}}.intersperse(' ')].compact.intersperse('<br>')
               when DC+'cache'
                 self[DC+'cache'].map{|c|[{_: :a, href: c.R.path, class: :chain}, ' ']}
               else
                 self[k].map{|v|v.respond_to?(:uri) ? v.R : CGI.escapeHTML(v.to_s)}.intersperse(' ')
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
                             HTML.render({_: :span, class: "w#{wordIndex[g.downcase]}", c: g}) # wrap match
                           }},{_: :hr}] if lines.size > 0 }}
      # word-highlight CSS
      graph['#abstracts'] = {Abstract => {_: :style, c: wordIndex.values.map{|i|".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}}}
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
  end
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

