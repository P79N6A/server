# coding: utf-8
class WebResource
  module HTML
    def self.render x
      case x
      when String
        x
      when Hash
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
        render({_: :a, href: x.uri,
                c: x[:label][0] || URI.unescape(x.fragment || (x.path && x.path[1..-1]) || x.host || '&#x279f;')}.
                 update(x[:id][0] ? {id: x[:id][0]} : {}).
                 update(x[:style][0] ? {style: x[:style][0]} : {}).
                 update(x[:class][0] ? {class: x[:class][0]} : {}).
                 update(x[:name][0] ? {name: x[:name][0]} : {}))
      when NilClass
        ''
      when FalseClass
        ''
      else
        CGI.escapeHTML x.to_s
      end
    end

    include URIs

    def self.strip body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type}
      html = Nokogiri::HTML.fragment body
      loseTags.map{|tag| html.css(tag).remove} if loseTags
      html.traverse{|e|
        e.attribute_nodes.map{|a|
          a.unlink unless keepAttr.member? a.name}} if keepAttr
      html.to_xhtml(:indent => 0)
    end

    def htmlDocument graph = {}
      @r ||= {}
      @r[:title] ||= graph[path+'#this'].do{|r|r[Title].justArray[0]}
      @r[:label] ||= {}
      @r[:Links] ||= {}
      htmlGrep graph, q['q'] if q['q']
      title = @r[:title] || [*path.split('/'),q['q'] ,q['f']].map{|e|e && URI.unescape(e)}.join(' ')
      css = -> s {{_: :style, c: ["\n",
                  ".conf/#{s}.css".R.readFile]}}
      cssFiles = [:icons]
      cssFiles.push :code if graph.values.find{|r|r.R.a SIOC+'SourceCode'}
      notfound = -> {
        dbg = @r.dup.update({'HTTP_ACCEPT' => accept, 'HTTP_ACCEPT_ENCODING' => (accept 'HTTP_ACCEPT_ENCODING'), 'HTTP_ACCEPT_LANGUAGE' => (accept 'HTTP_ACCEPT_LANGUAGE'), 'QUERY_STRING' => q}); dbg[:Response].delete 'Link'
        HTML.kv dbg}
      link = -> name, icon, style=nil {@r[:Links][name].do{|uri| [uri.R.data({id: name, label: icon, style: style}),"\n"]}}
      HTML.render ["<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n    \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n\n",
                   {_: :html, xmlns: "http://www.w3.org/1999/xhtml",
                    c: ["\n\n",
                        {_: :head,
                         c: ['', {_: :meta, charset: 'utf-8'}, {_: :title, c: title}, {_: :link, rel: :icon, href: '/.conf/icon.png'},
                             *@r[:Links].do{|links| links.map{|type,uri|
                                 {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                             css['site']].map{|e|['  ',e,"\n"]}}, "\n\n",
                        {_: :body,
                         c: ["\n",
                             link[:up, '&#9650;'], link[:prev, '&#9664;','float: left'], link[:next, '&#9654;','float: right'],
                             graph.empty? ? notfound[] : [(htmlTable graph), link[:down,'&#9660;']], "\n",
                             (htmlTree graph), "\n",
                             {_: :style, c: ["\n", @r[:label].map{|name,_|
                               "[name=\"#{name}\"] {background-color: #{'#%06x' % (rand 16777216)}}\n"}]}, "\n",
                             cssFiles.map{|f|css[f]}, "\n",
                             {_: :script, c: ["\n", '.conf/site.js'.R.readFile]}, "\n",
                            ]}, "\n",
                       ]}]
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
      graph['#abstracts'] = {Abstract => {_: :style, c: wordIndex.values.map{|i|".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}}}
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

class String
  # text -> HTML + (rel,href) tuple
  # <> or () URL wrapping stripped, trailing [,.] not captured
  def hrefs &blk
    pre, link, post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') + # pre-match
      (link.empty? && '' ||
       '<a class="link" href="' + link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') + '">' +
       (resource = link.R
        if blk && !(R::MITMhosts.member? resource.host) # TODO resolve original link of shortlink rehosts in background thread
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
        '') +
       '</a>') +
      (post.empty? && '' || post.hrefs(&blk)) # post-match recursion
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

