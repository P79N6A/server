# -*- coding: utf-8 -*-

def H x # HTML output
  case x
  when Hash # element
    void = [:img, :input, :link, :meta].member? x[:_]
    '<' + (x[:_] || 'div').to_s +                        # element name
      (x.keys - [:_,:c]).map{|a|                         # attribute name
      ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
        {"'"=>'%27', '>'=>'%3E',
         '<'=>'%3C'}[c]||c}.join + "'"}.join +
      (void ? '/' : '') + '>' + (H x[:c]) +              # children
      (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # element closer
  when Array # structure
    x.map{|n|H n}.join
  when R # hyperlink
    H x.href
  when String
    x
  when Symbol
    x.to_s
  when Float
    x.to_s
  when Integer
    x.to_s
  when NilClass
    ''
  else # call native #to_s and escape output
    x.to_s.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;')
  end
end

class H
  def H.[] h; H h end
end

class R

  def href name = nil
    {_: :a, href: uri, c: name || fragment || basename}
  end

  require 'nokogiri'
  def nokogiri
    Nokogiri::HTML.parse (open uri).read
  end

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove} if loseTags
    html.traverse{|e|
      e.attribute_nodes.map{|a|
        a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml(:indent => 0)}

  def R.ungunk host
    (host||'').sub(/^www./,'').sub(/\.(com|edu|net|org)$/,'')
  end

  Grep = -> graph, re {
    wordIndex = {}
    query = re.q['q']
    words = query.scan(/[\w]+/).map(&:downcase).uniq
    words.each_with_index{|word,i|wordIndex[word] = i}
    pattern = /#{words.join '.*'}/i
    highlight = /(#{words.join '|'})/i
    graph.map{|u,r|
      r.values.flatten.select{|v|v.class==String}.map(&:lines).flatten.map{|l|l.gsub(/<[^>]+>/,'')}.grep(pattern).do{|lines|
        r[Content] = []
        lines[0..5].map{|line|
          r[Content].unshift line[0..400].gsub(highlight){|g|
            H({_: :span, class: "w w#{wordIndex[g.downcase]}", c: g})}}}
      graph.delete u if r[Content].empty?}
    graph['#grep.CSS'] = {Content => H({_: :style, c: wordIndex.values.map{|i|
                                          ".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}}
  HTML = -> graph, re {
    e = re.env
    Grep[graph,re] if re.q.has_key? 'q'
    upPage = e[:Links][:up].do{|u|[{_: :a, c: '&#9650;', rel: :up, href: (CGI.escapeHTML u.to_s)},'<br clear=all>']}
    prevPage = e[:Links][:prev].do{|p|{_: :a, c: '&#9664;', rel: :prev, href: (CGI.escapeHTML p.to_s)}}
    nextPage = e[:Links][:next].do{|n|{_: :a, c: '&#9654;', rel: :next, href: (CGI.escapeHTML n.to_s)}}
    downPage = e[:Links][:down].do{|d|['<br clear=all>',{_: :a, c: '&#9660;', rel: :down, href: (CGI.escapeHTML d.to_s)}]}
    # rewrite graph-in-tree to HTML-in-tree and call H for character output
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 {_: :script, c: R['/js/ui.js'].readFile},
                 {_: :style, c: R['/css/base.css'].readFile}]},
            {_: :body,
             c: [upPage, prevPage, nextPage,
                 TabularView[graph,re], ({_: :span, style: 'font-size:8em', c: 404} if graph.empty?),
                 ([prevPage, nextPage] if graph.keys.size > 12), downPage]}]}]}

  # types shown in main column
  InlineMeta = [Title, Image, Content, Label]
  # types collapsed in abbreviated view
  VerboseMeta = [DC+'identifier', DC+'link', DC+'source', DC+'hasFormat', RSS+'comments', RSS+'em', RSS+'category', Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',SIOC+'has_discussion', SIOC+'reply_of', SIOC+'reply_to', SIOC+'num_replies', SIOC+'has_parent', SIOC+'attachment', Mtime, Podcast+'explicit', Podcast+'summary', Podcast+'subtitle', "http://wellformedweb.org/CommentAPI/commentRss","http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content"]

  TabularView = -> g, e, static=false {
    titles = {}
    e.env[:label] = {}
    (1..10).map{|i|
      e.env[:label]["quote"+i.to_s] = true}
    # sorting attribute
    p = e.q['sort'] || Date
    # sorting direction
    direction = e.q.has_key?('ascending') ? :id : :reverse
    # sorting datatype
    datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
    # column heading
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    keys -= InlineMeta
    keys -= VerboseMeta unless e.q.has_key? 'full'
    [{_: :table,
      c: [{_: :tbody,
           c: g.values.sort_by{|s|
             ((if p == 'uri'
               s[Title] || s[Label] || s.uri
              else
                s[p]
               end).justArray[0]||0).send datatype}.send(direction).map{|r|
             title = r[Title].justArray.select{|t|t.class==String}[0].do{|t|
               t = t.sub ReExpr, ''
               titles[t] ? nil : (titles[t] = t)}
             TableRow[r,e,p,direction,keys,title,static] unless static && !title
           }},
          ({_: :tr, c: keys.map{|k|
              q = e.q.merge({'sort' => k})
              if direction == :id
                q.delete 'ascending'
              else
                q['ascending'] = ''
              end
              href = CGI.escapeHTML R.qs q
              {_: :th, href: href, property: k, class: k == p ? 'selected' : '',
               c: {_: :a, href: href, class: Icons[k]||'', c: k.R.fragment||k.R.basename}}}} unless static)]},
     {_: :style, c: e.env[:label].map{|name,_| "[name=\"#{name}\"] {background-color: #{'#%06x' % (rand 16777216)}}\n"}},
     {_: :style, c: "[property=\"#{p}\"] {border-color:#999;border-style: solid; border-width: 0 0 .1em 0}"}]}

  TableRow = -> l,e,sort,direction,keys,title,static {
    this = l.R
    href = this.uri
    types = l.types
    rowID = if static
              'h' + rand.to_s.sha1 # random identifier which won't collide when mashed later on
            else # runtime binding
              if e.path[-1]=='/' # container
                e.selector # late bind of ordinal identifier. more readable/hackable than hash
              else # doc
                this.fragment # original identifier can be re-used
              end
            end
    monospace = types.member?(SIOC+'InstantMessage')||types.member?(SIOC+'MailMessage')
    isImg = types.member? Image
    fileResource = types.member?(Stat+'File') || types.member?(Stat+'CompressedFile') || types.member?(Container) || types.member?(Resource)

    actors = -> p {
      l[p].do{|o|
        o.justArray.uniq.map{|v|
          if v.respond_to?(:uri)
            v = v.R
            label = v.fragment || (v.basename && v.basename != '/' && (URI.unescape v.basename)) || (R.ungunk v.host)
            lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
            e.env[:label][lbl] = true
            {_: :a, href: v.uri, name: lbl, c: label}
          else
            v.to_s
          end
        }.intersperse(' ')}}

    [{_: :tr, href: href, id: rowID,
      c: ["\n",
          keys.map{|k|
            [{_: :td, property: k,
              c: case k
                 when 'uri'
                   [# label
                     l[Label].justArray.map{|v|
                       label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                       lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                       e.env[:label][lbl] = true
                       [{_: :a, href: href, name: lbl, c: label},' ']},
                     # title
                     (if title
                      {_: :a, class: :title, href: href, c: (CGI.escapeHTML title)}
                     elsif fileResource
                       {_: :a, href: href, c: [{_: :span, class: :gray, c: CGI.escapeHTML(File.dirname(this.path).gsub('/',' '))}, ' ', CGI.escapeHTML(File.basename this.path)]}
                      end),
                     (title ? '<br>' : ' '),
                     # links
                     [DC+'link', SIOC+'attachment', DC+'hasFormat'].map{|p|
                       l[p].justArray.map(&:R).group_by(&:host).map{|host,links|
                         group = R.ungunk (host||'')
                         e.env[:label][group] = true
                         {name: group, class: :links,
                          c: [{_: :a, name: group, href: host ? ('//'+host) : '/', c: group}, ' ', links.map{|link|
                                [{_: :a, href: link.uri, c: CGI.escapeHTML(link.uri)}.
                                   update(links.size < 9 ? {id: e.selector} : {}), ' ']}]}}},
                     # body
                     l[Content].justArray.map{|c|
                       monospace ? {_: :pre, c: c} : c },
                     # images
                     (['<br>', {_: :a, href: href,
                                c: {_: :img, class: :thumb,
                                    src: if this.host != e.host
                                     this.uri
                                   elsif this.ext.downcase == 'gif'
                                     href
                                   else
                                     '/thumbnail' + this.path
                                    end}}] if isImg)]
                 when Type
                   l[Type].justArray.uniq.map{|t|
                     icon = Icons[t.uri]
                     {_: :a, href: href, c: icon ? '' : (t.R.fragment||t.R.basename), class: icon}}
                 when Schema+'logo'
                   l[k].justArray.map{|logo|
                     if logo.respond_to?(:uri)
                       {_: :a, href: l[DC+'link'].justArray[0].do{|l|l.uri}||'#',
                        c: {_: :img, class: :logo, src: logo.uri}}
                     end
                   }
                 when From
                   actors[From]
                 when To
                   actors[To]
                 when Size
                   l[k].do{|sz|
                     sum = 0
                     sz.justArray.map{|v|
                       sum += v.to_i}
                     sum}
                 else
                   l[k].justArray.map{|v|
                     case v
                     when Hash
                       v.R
                     else
                       v
                     end
                   }.intersperse(' ')
                 end}, "\n"]}]},
     l[Image].do{|images|
       {_: :tr,
        c: [{_: :td, colspan: keys.size,
             c: images.justArray.map{|i|
               {_: :a, href: href,
                c: {_: :img, src: i.R.host == e.host ? i.R.path : i.uri, class: :preview}}}.intersperse(' ')}]}}]}

end
