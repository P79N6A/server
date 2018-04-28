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
      when Array
        x.map{|n|render n}.join
      when R
        render({_: :a, href: x.uri, id: 'link'+rand.to_s.sha2, c: x[:label][0] || (CGI.escapeHTML x.uri)})
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
      @r[:colors] ||= {'status' => 'background-color:#f3f3f3'}  # image references
      htmlGrep graph, q['q'] if q['q'] # markup grep-results
      css = -> s {{_: :style, c: ["\n", ".conf/#{s}.css".R.readFile]}} # inline CSS file(s)
      cssFiles = [:icons]; cssFiles.push :code if graph.values.find{|r|r.R.a SIOC+'SourceCode'}
      link = -> name,label { # markup doc-graph (exposed in HEAD) links
        @r[:links][name].do{|uri| [{_: :span, style: "font-size: 2.4em", c: uri.R.data({id: name, label: label})}, "\n"]}}
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
                         c: ["\n", link[:up, '&nbsp;&nbsp;&#9650;'], '<br>',
                             link[:prev, '&#9664;'],
                             (if graph.empty?
                              # Env -> Markup
                              [{_: :h1, c: 404},
                               HTML.kv(@r,@r)]
                             elsif (q.has_key? 'tabular') || (q.has_key? 't')
                               # Graph -> Markup
                               HTML.tabular graph.values, @r
                             else
                               treeize = Group[q['group']] || Group[q['g']] || Group[path == '/' ? 'decades' : 'tree']
                               # Graph -> Tree -> Markup
                               HTML.value Container, treeize[graph], @r
                              end),
                             link[:next, '&#9654;'], '<br>',
                             link[:down,'&#9660;'],
                             cssFiles.map{|f|css[f]}, "\n",
                             {_: :script, c: ["\n", '.conf/site.js'.R.readFile]}, "\n",
                            ]}, "\n" ]}]
    end

    def nokogiri; Nokogiri::HTML.parse (open uri).read end

    # Graph -> Graph
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
            l.gsub(/<[^>]+>/,'')[0..512].gsub(pattern){|g| # capture match
              HTML.render({_: :span, class: "w#{wordIndex[g.downcase]}", c: g}) # wrap match
            }} if lines.size > 0 }}
      # CSS
      graph['#abstracts'] = {Abstract => HTML.render({_: :style, c: wordIndex.values.map{|i|
                                                        ".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}
    end

    # HTML -> HTML
    def self.strip body, loseTags=%w{iframe script style}, keepAttr=%w{alt href id name rel src title type}
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove} if loseTags
      html.traverse{|e|
        e.attribute_nodes.map{|a|
          a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml(:indent => 0)
    end

    # Resource {k => v} -> Markup
    def self.kv hash, env
      {_: :table, class: :kv, c: hash.map{|k,vs|
         hide = k == Content && env['q'] && env['q'].has_key?('h')
         {_: :tr,
          c: (if k == Contains
              {_: :td, colspan: 2, c: vs.justArray.map{|v| HTML.value k,v,env }}
             else
               [{_: :td, class: :k,
                 c: {_: :span, class: Icons[k] || :label, c: Icons[k] ? '' : k}},
                {_: :td, class: :v,
                 c: ["\n ",
                     vs.justArray.map{|v|
                       HTML.value k,v,env}.intersperse(' ')]}]
              end)} unless hide}}
    end

    # ResourceList [reA,reB..] -> Markup
    def self.tabular resources, env
      ks = [[From, :from],
            [To,   :to],
            ['uri'],
            [Type],
            [Title,:title],
            [Abstract],
            [Date]]
      {_: :table, c: resources.sort_by{|r|r[Date].justArray[0] || ''}.reverse.map{|r|
         {_: :tr, c: ks.map{|k|
            keys = k[0]==Title ? [Title,Image,Video] : [k[0]]
            {_: :td, class: k[1],
             c: keys.map{|key|
               r[key].justArray.map{|v|
                 HTML.value key,v,env }.intersperse(' ')}}}}}}
    end

    # dispatch to type-specific markup
    def self.value k, v, env
      if 'uri' == k
        u = v.R
        {_: :a, href: u.uri, id: 'link'+rand.to_s.sha2, c: "#{u.host} #{u.path} #{u.fragment}"}
      elsif Content == k
        {class: :content, c: v}
      elsif Abstract == k
        v
      elsif Markup[k] # markup lambda defined on predicate
        Markup[k][v,env]
      elsif v.class == Hash # resource with data
        resource = v.R
        types = resource.types
        if types.member? InstantMessage
          Markup[InstantMessage][resource,env]
        elsif types.member? Container
          Markup[Container][v,env]
        elsif types.member? BlogPost
          Markup[BlogPost][v,env]
        else
          kv v,env
        end
      elsif v.class == WebResource
        v # resource without data - just a reference
      else
        CGI.escapeHTML v.to_s
      end
    end

    Markup[Title] = -> title,env=nil {{_: :h2, c: (CGI.escapeHTML title.to_s)}}

    Markup[Type] = -> t,env=nil {
      if t.respond_to? :uri
        t = t.R
        {_: :a, href: t.uri, c: Icons[t.uri] ? '' : (t.fragment||t.basename), class: Icons[t.uri]}
      else
        CGI.escapeHTML t.to_s
      end}

    Markup[Date] = -> date,env=nil {{_: :a, class: :date, href: '/' + date[0..13].gsub(/[-T:]/,'/'), c: date}}

    Markup[Container] = -> container , env {
      name = container[:name] || ''
      color = env[:colors][name] ||= (HTML.colorizeFG name)
      {class: "container depth#{container[:depth]}", style: color,
       c: [{_: :span, class: :name,  c: CGI.escapeHTML(name)},
           (container[Contains]||{}).values.map{|c|
             HTML.value(nil,c,env)}]}}

    Markup[BlogPost] = -> post , env {
      {_: :table, class: :post,
       c: {_: :tr,
           c: [{_: :td, class: :type, c: {_: :a, class: :newspaper, href: post.uri}},
               {_: :td, class: :contents, c: (HTML.kv post, env)}]}}}

    Markup[InstantMessage] = -> msg, env {
      [{c: [msg[Creator].map{|c|
              if c.respond_to? :uri
                name = c.R.fragment || c.R.basename || ''
                color = env[:colors][name] ||= (HTML.colorizeBG name)
                {_: :a, class: :comment, style: color, href: msg.uri, c: name}
              else
                CGI.escapeHTML c
              end}, ' ',
            {_: :span, class: :msgbody, c: [msg[Abstract], msg[Content]]},
            msg[Image].map{|i| Markup[Image][i,env]},
            msg[Video].map{|v| Markup[Video][v,env]},
            msg[Link].map(&:R)
          ]}," \n"]}

    # Graph -> Tree transforms

    # filesystem paths control tree-structure
    Group['tree'] = -> graph {
      tree = {}
      # visit resources
      graph.values.map{|resource|
        r = resource.R

        # walk to doc-graph node
        depth = 0
        cursor = tree
        r.parts.unshift(r.host||'').map{|name|
          cursor[Type] ||= R[Container] # containing node
          cursor[Contains] ||= {}       # contained nodes
           # create node and advance cursor to it
          cursor = cursor[Contains][name] ||= {depth: depth, name: name}
          depth += 1
        }

        # add resource data
        if !r.fragment # file metadata
          resource.map{|k,v|cursor[k] ||= v}
        else # fragment of doc
          cursor[Contains] ||= {}
          cursor[Contains][r.fragment] = resource
        end
      }; tree }

    # group toplevel year-dirs by decade
    Group['decades'] = -> graph {
      decades = {}
      other = []
      {'uri' => '/', Type => R[Container], Contains => decades}}

    def self.colorize k, bg=true
      if !k || k.empty?
        ''
      else
        "#{bg ? 'background-' : ''}color: #{'#%06x' % (rand 16777216)}"
      end
    end

    def self.colorizeBG k
      colorize k
    end

    def self.colorizeFG k
      colorize k, false
    end

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
