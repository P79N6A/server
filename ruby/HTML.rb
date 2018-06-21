# coding: utf-8
class WebResource
  module HTML
    SourceCode ||= Pathname.new(__FILE__).relative_path_from PWD

    # Markup -> HTML
    def self.render x
      case x
      when String
        x
      when Hash # HTML element
        void = [:img, :input, :link, :meta].member? x[:_]
        '<' + (x[:_] || 'div').to_s +                        # open tag
          (x.keys - [:_,:c]).map{|a|                         # attribute name
          ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
            {"'"=>'%27', '>'=>'%3E', '<'=>'%3C'}[c]||c}.join + "'"}.join +
          (void ? '/' : '') + '>' + (render x[:c]) +         # child nodes
          (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # close tag
      when Array # structure
        x.map{|n|render n}.join
      when R # link
        render({_: :a, href: x.uri, id: x[:id][0] || ('link'+rand.to_s.sha2), c: x[:label][0] || (CGI.escapeHTML x.uri)})
      when NilClass
        ''
      when FalseClass
        ''
      else
        CGI.escapeHTML x.to_s
      end
    end

    # Graph -> HTML
    def htmlDocument graph = {}
      @r ||= {} # environment
      title = graph[path+'#this'].do{|r| r[Title].justArray[0]} || # explicit title in RDF
              [*path.split('/'),q['q'] ,q['f']].map{|e|e && URI.unescape(e)}.join(' ') # path + keywords
      @r[:links] ||= {} # doc-level links
      @r[:images] ||= {}  # image references
      @r[:colors] ||= {}  # label -> CSS colors
      htmlGrep graph, q['q'] if q['q'] # markup search results
      css = -> s {{_: :style, c: ["\n", ".conf/#{s}.css".R.readFile]}} # inline CSS
      cssFiles = [:icons]; cssFiles.push :code if graph.values.find{|r|r.R.a SIOC+'SourceCode'}
      link = -> name,label {@r[:links][name].do{|uri|[uri.R.data({id: name, label: label}),"\n"]}} # markup doc (HEAD) link
      # HTML <- Markup
      HTML.render ["<!DOCTYPE html>\n\n",
                   {_: :html,
                    c: ["\n\n",
                        {_: :head,
                         c: [{_: :meta, charset: 'utf-8'},
                             {_: :title, c: title},
                             {_: :link, rel: :icon, href: '/.conf/icon.png'},
                             *@r[:links].do{|links| links.map{|type,uri|
                                 {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                             css['site']].map{|e|['  ',e,"\n"]}}, "\n\n",
                        {_: :body,
                         c: ["\n", link[:up, '&#9650;'], link[:prev, '&#9664;'], link[:next, '&#9654;'],
                             if graph.empty?
                               [{_: :h1, c: 404}, HTML.kv(@r,@r)]
                             else
                               if q.has_key? 't'
                                 # Graph -> Markup
                                 HTML.tabular graph.values, @r
                               else
                                 # Graph -> Tree -> Markup
                                 treeize = Group[q['g']] || Group[path == '/' ? 'decades' : 'tree']
                                 Markup[Container][treeize[graph], @r]
                               end
                             end,
                             link[:down,'&#9660;'],
                             cssFiles.map{|f|css[f]}, "\n",
                             {_: :script, c: ["\n",
                                              '.conf/site.js'.R.readFile]}, "\n"
                            ]}, "\n"
                       ]}]
    end

    Markup[Link] = -> ref, env=nil {
      u = ref.to_s
      [{_: :a, class: :link, title: u, id: 'l'+rand.to_s.sha2,
        href: u, c: u.sub(/^https?.../,'')[0..41]}," \n"]}

    Markup[Title] = -> title,env=nil,url=nil {
      title = CGI.escapeHTML title.to_s
      if url
        {_: :h3, c: {_: :a, class: :title, c: title, href: url, id: 'post'+rand.to_s.sha2}}
      else
        {_: :h3, c: title}
      end}

    Markup[Type] = -> t,env=nil {
      if t.respond_to? :uri
        t = t.R
        {_: :a, href: t.uri, c: Icons[t.uri] ? '' : (t.fragment||t.basename), class: Icons[t.uri]}
      else
        CGI.escapeHTML t.to_s
      end}

    Markup[Date] = -> date,env=nil,offset=0 {
      {_: :a, class: offset == 0 ? :date : :time,
       href: '/' + date[0..13].gsub(/[-T:]/,'/'), c: date[offset..-1]}}

    Markup[Creator] = -> c, env, urls=nil {
      puts urls
      if c.respond_to? :uri
        u = c.R
        name = u.fragment || u.basename.do{|b|b=='/' ? u.host : b} || u.host || 'user'
        color = env[:colors][name] ||= (HTML.colorizeBG name)
        {_: :a, class: :creator, style: color, href: urls.justArray[0] || c.uri, c: name}
      else
        CGI.escapeHTML (c||'')
      end}

    # {k => v} -> Markup
    def self.kv hash, env
      hash.delete :name
      ["\n",
       {_: :table, class: :kv,
        c: hash.sort_by{|k,vs|k.to_s}.reverse.map{|k,vs|
          type = k && k.R || '#untyped'.R
          hide = k == Content && env['q'] && env['q'].has_key?('h')
          [{_: :tr, name: type.fragment || type.basename,
            c: ["\n ",
                {_: :td, class: :k, c: Markup[Type][type]},"\n ",
                {_: :td, class: :v,
                 c: if k == Contains && vs.values.size > 1
                  tabular vs.values, env, false
                else
                  vs.justArray.map{|v|HTML.value k,v,env}.intersperse(' ')
                 end
                }]},
           "\n"] unless hide}}, "\n"]
    end

    # (k,v) -> Markup
    def self.value k, v, env
      if 'uri' == k
        u = v.R
        {_: :a, href: u.uri, id: 'link'+rand.to_s.sha2, c: "#{u.host} #{u.path} #{u.fragment}"}
      elsif Content == k
        v
      elsif Abstract == k
        v
      elsif Markup[k] # typed arc (vary arc to override default resource markup)
        Markup[k][v,env]
      elsif v.class == Hash # node w/ inlined data
        resource = v.R
        types = resource.types
        # typed node
        if types.member? InstantMessage
          Markup[InstantMessage][resource,env]
        elsif types.member?(BlogPost) || types.member?(Email)
          Markup[BlogPost][v,env]
        elsif types.member? Container
          Markup[Container][v,env]
        else # generic node
          kv v,env
        end
      elsif v.class == WebResource
        v # node reference
      else
        CGI.escapeHTML v.to_s
      end
    end

    # [resourceA,resourceB..] -> Markup
    def self.tabular resources, env, head = true
      ks = resources.map(&:keys).flatten.uniq
      {_: :table, class: :table,
       c: [({_: :tr,
             c: ks.map{|k|
               {_: :td, c: Markup[Type][k.R]}}} if head),
           resources.sort_by{|r|
             (case env['q']['sort']
              when 'date'
                r[Date].justArray[0]
              else
                r.R.basename
              end) || ''
           }.reverse.map{|r|
             {_: :tr,
              c: ks.map{|k|
                keys = k==Title ? [Title,Image,Video] : [k]
                {_: :td, class: k.R.fragment||k.R.basename,
                 c: keys.map{|key|
                   r[key].justArray.map{|v|
                     HTML.value key,v,env }.intersperse(' ')}}}}}]}
    end

    # Graph -> Tree transforms
    Group['flat'] = -> graph { graph }

    # group years by decade
    Group['decades'] = -> graph {
      decades = {}
      graph.values.map{|resource|
        name = resource.R.parts[0] || ''
        decade = (name.match /^\d{4}$/) ? name[0..2]+'0s' : '/'
        decades[decade] ||= {name: decade, Contains => {}}
        decades[decade][Contains][resource.uri] = resource}
      decades}

    ## Utility functions

    def self.colorize k, bg = true
      return '' if !k || k.empty? || BlankLabel.member?(k) || k.match(/^[0-9]+$/)
      "#{bg ? 'background-' : ''}color: #{'#%06x' % (rand 16777216)}"
    end
    def self.colorizeBG k; colorize k end
    def self.colorizeFG k; colorize k, false end

    # hypertext grep-results
    def htmlGrep graph, q
      wordIndex = {}
      args = POSIX.splitArgs q
      args.each_with_index{|arg,i| wordIndex[arg] = i }
      pattern = /(#{args.join '|'})/i
      # find matches
      graph.map{|u,r|
        keep = !(r.has_key?(Abstract)||r.has_key?(Content)) || r.to_s.match(pattern)
        graph.delete u unless keep}
      # highlight matches
      graph.values.map{|r|
        (r[Content]||r[Abstract]).justArray.map(&:lines).flatten.grep(pattern).do{|lines|
          r[Abstract] = lines[0..5].map{|l|
            l.gsub(/<[^>]+>/,'')[0..512].gsub(pattern){|g| # capture
              HTML.render({_: :span, class: "w#{wordIndex[g.downcase]}", c: g}) # wrap
            }} if lines.size > 0 }}
      # CSS
      graph['#abstracts'] = {Abstract => HTML.render({_: :style, c: wordIndex.values.map{|i|
                                                        ".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}
    end

    # dirty HTML -> cleaned, reformatted HTML
    def self.strip body, loseTags=%w{iframe script style}, keepAttr=%w{alt href id name rel src title type}
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove} if loseTags
      html.traverse{|e|
        e.attribute_nodes.map{|a|
          a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml(:indent => 0)
    end

    # parse HTML
    def nokogiri; Nokogiri::HTML.parse (open uri).read end

  end
  include HTML
  module Webize
    include URIs
    # HTML -> RDF
    def triplrHTML &f
      triplrFile &f
      yield uri, Type, R[Stat+'HTMLFile']
      n = Nokogiri::HTML.parse readFile
      n.css('title').map{|title| yield uri, Title, title.inner_text }
      n.css('meta[property="og:image"]').map{|m| yield uri, Image, m.attr("content").R }
    end

  end
  include Webize
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
