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
        render({_: :a, href: x.uri, id: x[:id][0] || ('link'+rand.to_s.sha2), class: x[:class][0], c: x[:label][0] || (CGI.escapeHTML x.uri)})
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
      @r ||= {} # HEAD
      title = graph[path+'#this'].do{|r| r[Title].justArray[0]} ||                     # explicit title
              [*path.split('/'),q['q'] ,q['f']].map{|e|e && URI.unescape(e)}.join(' ') # path + keywords

      # HEAD links
      @r[:links] ||= {}
      @r[:images] ||= {}
      @r[:colors] ||= {}

      # filter graph w/ HTML result
      htmlGrep graph, q['q'] if q['q']

      # name -> CSS tag
      css = -> s {{_: :style, c: ["\n", ".conf/#{s}.css".R.readFile]}}
      cssFiles = [:icons]; cssFiles.push :code if graph.values.find{|r|r.R.a SIOC+'SourceCode'}

      # HEAD links -> HTML
      link = -> name,label {@r[:links][name].do{|uri|[uri.R.data({id: name, label: label}),"\n"]}}

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
                         c: ["\n",
                             link[:up, '&#9650;'],
                             link[:prev, '&#9664;'],
                             link[:next, '&#9654;'],
                             if graph.empty?
                               [{_: :h1, c: {_: :a, id: :link, href: 'https://'+host+path, c: 404}}, HTML.kv(HTML.urifyHash(@r),@r)]
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

    Markup[Type] = -> t,env=nil {
      if t.respond_to? :uri
        t = t.R
        {_: :a, href: t.uri, c: Icons[t.uri] ? '' : (t.fragment||t.basename), class: Icons[t.uri]}
      else
        CGI.escapeHTML t.to_s
      end}

    # (k,v) tuple -> Markup
    def self.value k, v, env
      if 'uri' == k
        u = v.R
        {_: :a, href: u.uri, id: 'link'+rand.to_s.sha2, c: "#{u.host} #{u.path} #{u.fragment}"}
      elsif Content == k
        v
      elsif Abstract == k
        v
      elsif Markup[k] # typed predicate
        Markup[k][v,env]
      elsif v.class == Hash
        resource = v.R
        types = resource.types
        # typed object
        if types.member? InstantMessage
          Markup[InstantMessage][resource,env]
        elsif types.member?(BlogPost) || types.member?(Email)
          Markup[BlogPost][v,env]
        elsif types.member? Container
          Markup[Container][v,env]
        else
          kv v, env
        end
      elsif v.class == WebResource
        v
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
             (case env['query']['sort']
              when 'date'
                r[Date].justArray[0]
              else
                r.R.basename
              end) || ''
           }.reverse.map{|r|
             {_: :tr,
              c: ks.map{|k|
                keys = k==Title ? [Title,Image,Video] : [k]
                {_: :td,
                 c: keys.map{|key|
                   r[key].justArray.map{|v|
                     HTML.value key,v,env }.intersperse(' ')}}}}}]}
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
