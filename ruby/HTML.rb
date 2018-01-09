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
        render({_: :a, href: x.uri,
                style: x[:style][0],
                class: x[:class][0],
                c: x[:label][0] || URI.unescape(x.fragment || (x.path && x.basename != '/' && x.basename) || x.host || '&#x279f;')}.
                 update(x[:id][0] ? {id: x[:id][0]} : {}).
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
    InlineMeta = ['uri', Title, Image, Video, Abstract, From, To, Size, Date, Type, Content, Label, DC+'cache', DC+'link', DC+'note', Atom+'link', RSS+'link', RSS+'guid', DC+'hasFormat', SIOC+'channel', SIOC+'attachment', SIOC+'user_agent', Stat+'contains']
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
      if q.has_key?('1')
        resources  = graph.values
        resources.map{|re|
          re.map{|p,o|
            one = graph[''] ||= {'uri' => ''}
            unless p=='uri'
              one[p] ||= []
              o.justArray.map{|o|
                one[p].push o unless one[p].member?(o)}
            end}
          graph.delete re.uri unless re.uri == '' }
      end
      query = q['q'] || q['f']
      title = @r[:title] || [*path.split('/'), query].join(' ')
      useGrep = path.split('/').size > 3 # search-provider suggestion
      link = -> name,icon {@r[:Links][name].do{|l| l.R.data({id: name, label: icon})}}

      HTML.render ["<!DOCTYPE html>\n",
                   {_: :html,
                    c: [{_: :head,
                         c: [{_: :meta, charset: 'utf-8'}, {_: :title, c: title}, {_: :link, rel: :icon, href: '/.conf/icon.png'},
                             %w{code icons site}.map{|s|{_: :style, c: ".conf/#{s}.css".R.readFile}},
                             @r[:Links].do{|links|
                               links.map{|type,uri|
                                 {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}
                               }},
                             {_: :script, c: '.conf/site.js'.R.readFile}]},
                        {_: :body,
                         c: [link[:up, '&#9650;'], link[:prev, '&#9664;'], link[:next, '&#9654;'],
                             {class: :scroll, c: (htmlTree graph)},
                             !empty && (htmlTable graph),
                             path!='/' && {class: :search,
                                           c: {_: :form,
                                               c: [{_: :a, id: :query, class: :find, href: (query ? '?head' : '') + '#searchbox' },
                                                   {_: :input, id: :searchbox, name: useGrep ? 'q' : 'f',
                                                    placeholder: useGrep ? :grep : :find
                                                   }.update(query ? {value: query} : {})]}},
                             {_: :style, c: @r[:label].map{|name,_|
                                color = '#%06x' % (rand 16777216)
                                "[name=\"#{name}\"] {background-color: #{color}}\n"}},
                             !empty && link[:down, '&#9660;'],
                             empty && [{_: :a, id: :nope, class: :notfound, style: "color:#{'#%06x' % (rand 16777216)}", c: 404, href: dirname},
                                       {_: :table, class: :env, c: @r.map{|k,vs|
                                          {_: :tr,
                                           c: [{_: :td, c: k},
                                               {_: :td, c: vs.justArray.map{|v|CGI.escapeHTML v.to_s}.intersperse(' ')}]}}}]]}]}]
    end

    def nokogiri
      Nokogiri::HTML.parse (open uri).read
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
  # text -> HTML. also a triplr yielding RDF to supplied block
  # '(' required to capture ')', <> and ()-wrapping stripped, comma or period after URI not captured
  def hrefs &blk
    pre, link, post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escaped pre-match
      (link.empty? && '' ||
       '<a class="link" href="' + link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') + '">' + # HTML link
       (yield(link.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) ? R::Image : (link.match(/(youtube.com|(mkv|mp4|webm)$)/i) ? R::Video : R::Link), link.R) if blk; '') + # RDF link
       '</a>') +
      (post.empty? && '' || post.hrefs(&blk)) # again on tail
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

