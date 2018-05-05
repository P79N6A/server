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
      when R # hyperlink
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
      title = graph[path+'#this'].do{|r| r[Title].justArray[0]} ||                   # title in RDF ||
              [*path.split('/'),q['q'] ,q['f']].map{|e|e && URI.unescape(e)}.join(' ') # path as title
      @r[:links] ||= {} # doc-graph links
      @r[:images] ||= {}  # image references
      @r[:colors] ||= {'status' => 'background-color:#222', 'twitter.com' => 'background-color:#000'}
      htmlGrep graph, q['q'] if q['q'] # filter graph
      css = -> s {{_: :style, c: ["\n", ".conf/#{s}.css".R.readFile]}} # inline CSS file(s)
      cssFiles = [:icons]; cssFiles.push :code if graph.values.find{|r|r.R.a SIOC+'SourceCode'}
      link = -> name,label { # markup graph-doc (HEAD) links
        @r[:links][name].do{|uri| [uri.R.data({id: name, label: label}), "\n"]}}
      # Markup -> HTML
      HTML.render ["<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n    \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n\n",
                   {_: :html, xmlns: "http://www.w3.org/1999/xhtml",
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
                                 treeize = Group[q['group']] || Group[q['g']] || Group[path == '/' ? 'decades' : 'tree']
                                 Markup[Container][treeize[graph], @r]
                               end
                             end,
                             link[:down,'&#9660;'],
                             cssFiles.map{|f|css[f]}, "\n", {_: :script, c: ["\n", '.conf/site.js'.R.readFile]}, "\n"]}, "\n"]}]
    end

    # key+value -> Markup
    def self.value k, v, env
      if 'uri' == k
        u = v.R
        {_: :a, href: u.uri, id: 'link'+rand.to_s.sha2, c: "#{u.host} #{u.path} #{u.fragment}"}
      elsif Content == k
        v
      elsif Abstract == k
        v
      elsif Markup[k]
        Markup[k][v,env]
      elsif v.class == Hash # resource
        resource = v.R
        types = resource.types
        # type-specific markup
        if types.member? InstantMessage
          Markup[InstantMessage][resource,env]
        elsif types.member? Container
          Markup[Container][v,env]
        elsif types.member?(BlogPost) || types.member?(Email)
          Markup[BlogPost][v,env]
        else # untyped resource
          kv v,env
        end
      elsif v.class == WebResource
        v # resource reference
      else
        CGI.escapeHTML v.to_s
      end
    end

    Markup[Link] = -> ref, env=nil {
      u = ref.to_s
      [{_: :a, class: :link, title: u, href: u, c: u.sub(/^https?.../,'')}," \n"]}

    Markup[Title] = -> title,env=nil,url=nil {
      title = CGI.escapeHTML title.to_s
      if url
        {_: :a, class: :title, c: title, href: url, id: 'post'+rand.to_s.sha2}
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

    Markup[Date] = -> date,env=nil {{_: :a, class: :date, href: '/' + date[0..13].gsub(/[-T:]/,'/'), c: date}}

    Markup[Creator] = -> c, env {
      if c.respond_to? :uri
        u = c.R
        name = u.fragment || u.basename.do{|b|b=='/' ? u.host : b} || u.host || 'user'
        color = env[:colors][name] ||= (HTML.colorizeBG name)
        {_: :a, class: :creator, style: color, href: c.uri, c: name}
      else
        CGI.escapeHTML c
      end}

    Markup[Container] = -> container , env {
      container.delete Type
      name = (container.delete :name) || ''
      contents = (container.delete(Contains)||{}).values
      color = env[:colors][name] ||= (HTML.colorizeBG name)
      {class: :container, style: color,
       c: [{_: :span, class: :name, style: color, c: CGI.escapeHTML(name)}, # label
           if env['q'].has_key? 't'
             HTML.tabular contents, env
           else # child nodes
             contents.map{|c|HTML.value(nil,c,env)}
           end,
           HTML.kv(container, env)]}}

    Markup[BlogPost] = Markup[Email] = -> post , env {
      # hidden fields in default view
      [:name, Type, Comments, Identifier, RSS+'comments', SIOC+'num_replies'].map{|attr|post.delete attr}
      # bind data
      canonical = post.delete 'uri'
      cache = post.delete(Cache).justArray[0]
      titles = post.delete(Title).justArray.map(&:to_s).map(&:strip).uniq
      date = post.delete(Date).justArray[0]
      from = post.delete(From).justArray
        to = post.delete(To).justArray

      {class: :post,
       c: [{_: :a, class: :newspaper, href: cache||canonical},
           titles.map{|title|
             Markup[Title][title,env,canonical]},
           {_: :table,
            c: {_: :tr,
                c: [{_: :td, c: from.map{|f|Markup[Creator][f,env]}, class: :from},
                    {_: :td, c: '&rarr;'},
                    {_: :td, c: to.map{|f|Markup[Creator][f,env]}, class: :to}]}},
           (HTML.kv post, env), # remaining fields in default render
           (['<br>', Markup[Date][date]] if date)]}}

    Markup[InstantMessage] = -> msg, env {
      [{c: [{class: :creator,
             c: msg[Creator].map{|c|Markup[Creator][c,env]}}, ' ',
            {_: :span, class: :msgbody,
             c: [msg[Abstract],
                 msg[Content]]},
            msg[Image].map{|i| Markup[Image][i,env]},
            msg[Video].map{|v| Markup[Video][v,env]},
            msg[Link].map(&:R)
          ]}," \n"]}

    # Resource {k => v} -> Markup
    def self.kv hash, env
      hash.delete :name
      {_: :table, class: :kv, c: hash.map{|k,vs|
         hide = k == Content && env['q'] && env['q'].has_key?('h')
         {_: :tr,
          c: [{_: :td, class: :k, c: Markup[Type][k.R]},
              {_: :td, class: :v,
               c: ["\n ",
                   vs.justArray.map{|v|
                     HTML.value k,v,env}.intersperse(' ')]}]} unless hide}}
    end

    # ResourceList [rA,rB..] -> Markup
    def self.tabular resources, env
      ks = resources.map(&:keys).flatten.uniq - ['uri', Identifier]
      ks -= [Content] if env['q'].has_key? 'h'
      {_: :table, class: :table,
       c: [{_: :tr, c: ks.map{|k|{_: :td, c: Markup[Type][k.R]}}},
           resources.sort_by{|r|r[Date].justArray[0] || ''}.reverse.map{|r|
             {_: :tr, c: ks.map{|k|
                keys = k==Title ? [Title,Image,Video] : [k]
                {_: :td, class: k.R.fragment||k.R.basename,
                 c: keys.map{|key|
                   r[key].justArray.map{|v|
                     HTML.value key,v,env }.intersperse(' ')}}}}}]}
    end

    # Graph -> Tree transforms

    # filesystem tree
    Group['tree'] = -> graph {
      tree = {}
      # visit resources
      (graph.class==Array ? graph : graph.values).map{|resource|
        r = resource.R
        # walk to doc-graph
        cursor = tree
        r.parts.unshift(r.host||'').map{|name|
          cursor[Type] ||= R[Container] # containing node
          cursor[Contains] ||= {}       # contained nodes
           # create node and advance cursor
          cursor = cursor[Contains][name] ||= {name: name}}

        # reference resource-data
        if !r.fragment # graph-meta
          resource.map{|k,v|cursor[k] ||= v}
        else # resources
          cursor[Contains] ||= {}
          cursor[Contains][r.fragment] = resource
        end
      }; tree }

    # group year directories by decade
    Group['decades'] = -> graph {
      decades = {}
      graph.values.map{|resource|
        name = resource.R.parts[0] || ''
        decade = (name.match /^\d{4}$/) ? name[0..2]+'0s' : '/'
        decades[decade] ||= {name: decade, Type => R[Container], Contains => {}}
        decades[decade][Contains][resource.uri] = resource}
      {Contains => decades}}

    def self.colorize k, bg = true
      if !k || k.empty?
        ''
      else
        "#{bg ? 'background-' : ''}color: #{'#%06x' % (rand 16777216)}"
      end
    end

    ## Utility functions

    def self.colorizeBG k
      colorize k
    end

    def self.colorizeFG k
      colorize k, false
    end

    # colorized grep matches, in Abstract field
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

    # dirty HTML -> cleaned/reformatted HTML
    def self.strip body, loseTags=%w{iframe script style}, keepAttr=%w{alt href id name rel src title type}
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove} if loseTags
      html.traverse{|e|
        e.attribute_nodes.map{|a|
          a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml(:indent => 0)
    end

    # parse HTML at URI to in-memory structure
    def nokogiri; Nokogiri::HTML.parse (open uri).read end

  end
  module Webize

    # HTML -> RDF
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
