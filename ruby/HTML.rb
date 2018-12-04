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

      # HEAD links
      @r ||= {}
      @r[:links] ||= {}
      @r[:images] ||= {}
      @r[:colors] ||= {}

      # title
      title = graph[path+'#this'].do{|r|
        r[Title].justArray[0]} || # title in RDF
              [*path.split('/'), q['q'], q['f']].
                map{|e|
        e && URI.unescape(e)}.join(' ') # path + keyword derived title

      # name -> CSS
      css = -> s {{_: :style, c: ["\n", ".conf/#{s}.css".R.readFile]}}
      cssFiles = %w{site icons code}

      # header (k,v) -> HTML
      link = -> key, displayname {
        @r[:links][key].do{|uri|
          [uri.R.data({id: key, label: displayname}),
           "\n"]}}

      # filtered graph -> HTML
      htmlGrep graph, q['q'] if q['q']

      # Markup -> HTML
      HTML.render ["<!DOCTYPE html>\n\n",
                   {_: :html,
                    c: ["\n\n",
                        {_: :head,
                         c: [{_: :meta, charset: 'utf-8'},
                             {_: :title, c: title},
                             *@r[:links].do{|links|
                               links.map{|type,uri|
                                 {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}}
                            ].map{|e|['  ',e,"\n"]}}, "\n\n",
                        {_: :body, style: track? ? 'background-color: red' : '',
                         c: ["\n",
                             link[:up, '&#9650;'],
                             link[:prev, '&#9664;'],
                             link[:next, '&#9654;'],
                             if path == '/' && env['SERVER_PORT'] == '80'
                               {_: :a, id: :tls, href: 'https://'+host+path, c: '&nbsp;&#128274;&nbsp;'}
                             end,
                             if graph.empty?
                               HTML.kv (HTML.urifyHash @r), @r
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
                             {_: :script, c: ["\n", '.conf/site.js'.R.readFile]}, "\n"
                            ]}, "\n" ]}]
    end

    Markup[Type] = -> t,env=nil {
      if t.respond_to? :uri
        t = t.R
        {_: :a, href: t.uri, c: Icons[t.uri] ? '' : (t.fragment||t.basename), class: Icons[t.uri]}
      else
        CGI.escapeHTML t.to_s
      end}

    # typed value -> Markup
    def self.value k, v, env
      if Abstract == k
        v # HTML content
      elsif Content == k
        v # HTML content
      elsif Markup[k] # predicate-type keyed
        Markup[k][v,env]
      elsif v.class == Hash # object-type keyed
        resource = v.R
        types = resource.types
        if types.member? InstantMessage
          Markup[InstantMessage][resource,env]
        elsif types.member?(BlogPost) || types.member?(Email)
          Markup[BlogPost][v,env]
        elsif types.member? Container
          Markup[Container][v,env]
        else
          kv v, env
        end
      elsif k == 'uri'
        v.R # reference
      elsif v.class == WebResource
        v   # reference
      else # renderer undefined
        CGI.escapeHTML v.to_s
      end
    end

    # (dirty) HTML -> (cleaned, pretty printed) HTML
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

class String
  # text -> HTML. yield (rel,href) tuples to code-block
  def hrefs &blk
    # leading/trailing [<>()] stripped, trailing [,.] dropped
    pre, link, post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') + # pre-match
      (link.empty? && '' ||
       '<a class="link" href="' + link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') + '">' +
       (resource = link.R
        if blk
          type = case link
                 when /(gif|jpg|jpeg|jpg:large|png|webp)$/i
                   R::Image
                 when /(youtube.com|(mkv|mp4|webm)$)/i
                   R::Video
                 else
                   R::Link
                 end
          yield type, resource
        end
        CGI.escapeHTML(resource.uri.sub /^http:../,'')) +
       '</a>') +
      (post.empty? && '' || post.hrefs(&blk)) # recursion on post-match tail
  rescue
    puts "failed to hypertextify #{self}"
    ''
  end
end
