class WebResource
  module HTML

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
               (r.R.environment(@r).htmlTableRow p,direction,keys)}.intersperse("\n")},
            {_: :tr, c: [From,Type,'uri',*keys,DC+'cache',Date,Size].map{|k| # header row
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

      # cells

      typeTag = -> {
        self[Type].uniq.select{|t|t.respond_to? :uri}.map{|t|
          {_: :a, href: uri, c: Icons[t.uri] ? '' : (t.R.fragment||t.R.basename), class: Icons[t.uri]}}}


      title = -> {
        self[Title].compact.map{|t|
          name = a(SIOC+'Tweet') ? basename : tld
          @r[:label][name] = true
          {_: :a, class: :title, href: uri + ((a Container) ? '?head' : ''), name: name,
           c: (CGI.escapeHTML t.to_s)}.update(if identified || (inDoc && !fragment)
                                              {}
                                             else
                                               identified = true
                                               {id: (inDoc && fragment) ? fragment : 'r'+sha2, primary: :true}
                                              end)}.intersperse(' ')}

      labels = -> {
        self[Label].compact.map{|v|
          {_: :a, class: :label, href: uri,
           c: (CGI.escapeHTML (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v))}}.intersperse(' ')}

      abstract = -> {self[Abstract]}

      content = -> {
        self[Content].map{|c|
          if (a SIOC+'SourceCode') || (a SIOC+'MailMessage')
            {_: :pre, c: c}
          elsif a SIOC+'InstantMessage'
            {_: :span, class: :monospace, c: c}
          else
            c
          end
        }.intersperse(' ') unless q.has_key?('head')}

      linkTable = -> {
        links = LinkPred.map{|p|self[p]}.flatten.compact.map(&:R).select{|l|!@r[:links].member? l}.sort_by &:tld
        {_: :table, class: :links,
         c: links.group_by(&:host).map{|host,links|
           tld = links[0] && links[0].tld || 'none'
           traverse = links.size <= 16
           @r[:label][tld] = true
           {_: :tr,
            c: [({_: :td, class: :host, c: R['//'+host]} if host),
                {_: :td, class: :path, colspan: host ? 1 : 2,
                 c: links.map{|link|
                   @r[:links].push link
                   [link.data((traverse ? {id: 'link'+rand.to_s.sha2, name: tld} : {})),' ']}}]}}} unless links.empty?}

      photos = -> { # scan RDF for not-yet-shown resourcs
        images = []
        images.push self if types.member?(Image) # as subject of triple
        self[Image].do{|i|images.concat i}      # as object of triple
        images.map(&:R).select{|i|!@r[:images].member? i}.map{|img|
          @r[:images].push img # seen
          {_: :a, class: :thumb, href: uri,
           c: [{_: :img, src: if !img.host || img.host == @r['HTTP_HOST'] # thumbnailify locally-hosted images
                 img.path + '?preview'
               else
                 img.uri
                end},'<br>',
               {_: :span, class: :host, c: host},
               {_: :span, class: :notes, c: (CGI.escapeHTML img.path)}]}}}

      videos = -> {
        self[Video].map(&:R).map{|video|
          {class: :video,
           c: [{_: :video, src: video.uri, controls: :true}, '<br>',
               {_: :span, class: :notes, c: video.basename}]}}}

      fromTo = -> {
        {class: :fromTo,
         c: [[Creator,SIOC+'addressed_to'].map{|edge|
               self[edge].map{|v|
                 if v.respond_to?(:uri) && v.R.path
                   v = v.R
                   id = rand.to_s.sha2
                   # domain-specific index-location pointer
                   if a SIOC+'MailMessage' # messages*address*month
                     R[v.path + '?head#r' + sha2].data({id: 'address_'+id, label: v.basename})
                   elsif a SIOC+'Tweet'
                     if edge == Creator  # tweets*author*day
                       @r[:label][v.basename] = true
                       R[datePath[0..-4] + '*/*twitter.com.'+v.basename+'*#r' + sha2].data({id: 'twit'+id, name: v.basename, label: v.basename})
                     else # tweets*hour
                       R[datePath + '*twitter*#r' + sha2].data({id: 'tweet'+id, label: :twitter})
                     end
                   elsif a SIOC+'BlogPost'
                     R[datePath ? (datePath[0..-4] + '*/*' + (v.host||'') + '*#r' + sha2) : ('//'+host)].data({id: 'post'+id, label: v.host})
                   else
                     v
                   end
                 else
                   {_: :span, c: (CGI.escapeHTML v.to_s)}
                 end}.intersperse(' ')}.map{|a|a.empty? ? nil : a}.compact.intersperse('&rarr;'),
             self[SIOC+'user_agent'].map{|a|['<br>',{_: :span, class: :notes, c: a}]}]}}

      timeStamp = -> {
        [({_: :a, class: :date, href: datePath + '#r' + sha2, c: date} if datePath),
         self[DC+'note'].map{|n|{_: :span, class: :notes, c: n}}.intersperse(' ')].compact.intersperse('<br>')}

      size = -> {
        sum = 0
        self[Size].map{|v|sum += v.to_i}
        sum == 0 ? '' : sum
      }

      cacheLink = -> {self[DC+'cache'].map{|c|[{_: :a, id: '#c'+sha2, href: c.uri, class: :chain}, ' ']}}

      main = -> {
        [labels[],
         title[],
         abstract[],
         linkTable[],
         content[],
         photos[],
         videos[],
        ].intersperse(' ')}

      unless q.has_key?('head') && self[Title].empty? && self[Abstract].empty? # in header-mode, title and/or abstract is required
        {_: :tr,
         c: [[fromTo, typeTag, main].map{|producer|
               {_: :td, c: producer[]}},
             keys.map{|k|
               {_: :td, property: k, c: self[k].map{|v|v.respond_to?(:uri) ? v.R : CGI.escapeHTML(v.to_s)}.intersperse(' ')}},
             [cacheLink, timeStamp, size].map{|producer|
               {_: :td, c: producer[]}}]}
      end
    end
  end
end
