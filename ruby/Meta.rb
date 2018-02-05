class WebResource
  # basic metadata

  module HTML
    def self.kv hash
      {_: :table, class: :kv,
       c: hash.map{|k,vs|
         {_: :tr,
          c: [{_: :td, class: :key, c: ["\n", k]},
              {_: :td, class: :val, c: ["\n ",
                           vs.justArray.map{|v|
                             c = v.class
                             if c == Hash
                               kv v # another kv hash
                             elsif c == TrueClass
                               {_: :a, class: :check}
                             elsif c == FalseClass
                               {_: :a, class: :ban}
                             elsif !([Fixnum,String].member? c)
                               {_: :a, class: :cog, c: c}
                             else
                               CGI.escapeHTML v.to_s
                             end
                           }.intersperse(' ')]}]}}}
    end

    def tableCellTitle
      self[Title].compact.map{|t|
        meta = {id: inDoc ? fragment : 'r'+sha2,
                class: :title,
                label: CGI.escapeHTML(t.to_s)}
        name = if a SIOC+'Tweet'
                 parts[1]
               elsif a SIOC+'ChatLog'
                 CGI.unescape(basename).split('#')[0]
               elsif inDoc && !fragment # doc itself
                 nil
               elsif uri[-1] == '/'
                 'dirname'
               end
        if name
          meta.update({name: name})
          @r[:label][name] = true
        end
        link = uri.R
        link += '?head' if a Container
        link.data meta}.intersperse(' ')
    end

    def tableCellLabels
      self[Label].compact.map{|v|
        {_: :a, class: :label, href: uri,
         c: (CGI.escapeHTML (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v))}}.intersperse(' ')
    end

    def tableCellAbstract
      [self[Abstract],
       self[DC+'note'].map{|n|
         {_: :a, href: uri, class: :notes, c: CGI.escapeHTML(n.to_s)}}.intersperse(' ')]
    end

    def tableCellTypes
      self[Type].uniq.select{|t|t.respond_to? :uri}.map{|t|
        {_: :a, href: uri, c: Icons[t.uri] ? '' : (t.R.fragment||t.R.basename), class: Icons[t.uri]}}
    end

    LinkPred = [DC+'link', SIOC+'attachment', Stat+'contains', Atom+'link', RSS+'link']

    def tableCellLinks
      links = LinkPred.map{|p|self[p]}.flatten.compact.map(&:R).select{|l|!@r[:links].member? l}.sort_by &:tld
      {_: :table, class: :links,
       c: links.group_by(&:host).map{|host,links|
         tld = links[0] && links[0].tld || 'none'
         traverse = links.size <= 16
         @r[:label][tld] = true
         {_: :tr,
          c: [{_: :td, class: :path, colspan: host ? 1 : 2,
               c: links.map{|link|
                 @r[:links].push link
                 [link.data((traverse ? {id: 'link'+SecureRandom.hex(8), name: tld} : {})),' ']}},
              ({_: :td, class: :host, c: R['//'+host]} if host)
             ]}}} unless links.empty?
    end

    def tableCellCache
      self[DC+'cache'].map{|c|
        {_: :a, id: 'c'+sha2, href: c.uri, class: :chain}}.intersperse ' '
    end

    def tableCellSize
      sum = 0
      self[Size].map{|v|sum += v.to_i}
      sum == 0 ? '' : sum
    end

    def tableCellDate
      date = self[Date].sort[0]
      datePath = '/' + date[0..13].gsub(/[-T:]/,'/') if date
      {_: :a, class: :date, href: datePath + '#r' + sha2, c: date} if datePath
    end

  end

end
