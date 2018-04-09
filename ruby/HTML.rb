# coding: utf-8
class WebResource
  module HTML
    include URIs

    Contain = {}
    Markup = {}

    # containe year-directories at fs-root in additional decade-container
    Contain['decades'] = -> graph {

    }

    # markup RDF type-tag
    Markup[Type] = -> t,env=nil {
      if t.respond_to? :uri
        t = t.R
        {_: :a, href: t.uri, c: Icons[t.uri] ? '' : (t.fragment||t.basename), class: Icons[t.uri]}
      else
        CGI.escapeHTML t.to_s
      end}

    Markup[Date] = -> date,env=nil { {_: :a, class: :date, href: '/' + date[0..13].gsub(/[-T:]/,'/'), c: date} }

    # Markup -> String
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

    # (p,[o]) -> Markup
    def self.value k, vs, env
      vs.justArray.map{|v|
        if Markup[k]
          Markup[k][v,env]
        elsif v.class == Hash
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
          v
        elsif k == Content
          v
        elsif k == Abstract
          v
        elsif k == 'uri'
          u = v.R
          {_: :a, href: u.uri, id: 'link'+rand.to_s.sha2, c: "#{u.host} #{u.path} #{u.fragment}"}
        else
          CGI.escapeHTML v.to_s
        end
      }
    end

    # [resource] -> Markup
    def self.heading resources, env
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

    # { k => v } -> Markup
    def self.kv hash, env
      {_: :table, class: :kv, c: hash.map{|k,vs|
         hide = k == Content && env['q'] && env['q'].has_key?('h')
         style = env[:colors][k] ||= HTML.colorize(k)
         {_: :tr,
          c: (if k == Contains
              {_: :td, colspan: 2, c: vs.justArray.map{|v| HTML.value k,v,env }}
             else
               [{_: :td, class: :k, style: style,
                 c: {_: :span, class: Icons[k] || :label, c: Icons[k] ? '' : k}},
                {_: :td, class: :v, style: style,
                 c: ["\n ",
                     vs.justArray.map{|v| HTML.value k,v,env }.intersperse(' ')]}]
              end)} unless hide}}
    end

    def htmlDocument graph = {}
      @r ||= {} # env
      title = graph[path+'#this'].do{|r| r[Title].justArray[0]} || # explicit title
              [*path.split('/'),q['q'] ,q['f']].map{|e|e && URI.unescape(e)}.join(' ') # pathname
      @r[:links] ||= {} # document-level links
      @r[:images] ||= {}  # image references
      @r[:colors] ||= {}  # image references
      htmlGrep graph, q['q'] if q['q']
      css = -> s {{_: :style, c: ["\n", ".conf/#{s}.css".R.readFile]}}
      cssFiles = [:icons]
      cssFiles.push :code if graph.values.find{|r|r.R.a SIOC+'SourceCode'}
      link = -> name,label {
        @r[:links][name].do{|uri| [{_: :span, style: "font-size: 2.4em", c: uri.R.data({id: name, label: label})}, "\n"]}}
      nodata = graph.empty?
      # output
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
                             (if q.has_key? 'head'
                              HTML.heading graph.values, @r # tabular view
                             elsif nodata
                               [{_: :h1, c: 404}, HTML.kv(@r,@r)] # 404
                             else # parametric graph-to-tree transform, then markup the tree (of recursively nested containing nodes)
                               HTML.value Container, [(Contain[q['c']] || Contain[path == '/' ? 'decades' : 'tree'])[graph]], @r
                              end),
                             link[:next, '&#9654;'], '<br>',
                             link[:down,'&#9660;'],
                             cssFiles.map{|f|css[f]}, "\n",
                             {_: :script, c: ["\n", '.conf/site.js'.R.readFile]}, "\n",
                            ]}, "\n" ]}]
    end

    def nokogiri; Nokogiri::HTML.parse (open uri).read end

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

      # highlighting CSS
      graph['#abstracts'] = {Abstract => HTML.render({_: :style, c: wordIndex.values.map{|i|
                                                        ".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}
    end

    def self.colorize k
      if k.empty?
        ''
      elsif [Date, Type, To, From, DC+'cache', Size].member? k # base metadata
        "background-color: #ddd; color: #000"
      elsif [Contains, Content, Title, Link, Image, Video, 'status', 'uri'].member? k # content & title
        "background-color: #000; color: #fff"
      else # oddball metadata, colorize it
        "background-color: #{'#%06x' % (rand 16777216)}; color: #000"
      end
    end

    def self.strip body, loseTags=%w{iframe script style}, keepAttr=%w{alt href id name rel src title type}
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove} if loseTags
      html.traverse{|e|
        e.attribute_nodes.map{|a|
          a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml(:indent => 0)
    end

  end
  include HTML
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
