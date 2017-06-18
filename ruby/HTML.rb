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

  HTML = -> g,re {
    # extract graph data to a tree
    graph = {}
    g.each_triple{|s,p,o| s=s.to_s; p=p.to_s
      graph[s] ||= {'uri' => s}
      graph[s][p] ||= []
      graph[s][p].push [RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}

    e = re.env
    e[:label] ||= {}; (1..15).map{|i|e[:label]["quote"+i.to_s] = true}
    dir = re.path[-1] == '/'
    up = if re.q.has_key? 'full'
           R.qs re.q.reject{|k|k=='full'}.merge({'abbr' => ''})
         elsif dir && re.path != '/'
           re.justPath.dirname + '?' + re.env['QUERY_STRING']
         end
    expand = {_: :a, id: :down, href: (R.qs re.q.reject{|k|k=='abbr'}.merge({'full' => ''})), class: :expand, c: "&#9660;"} if dir && !re.q.has_key?('full')
    prevPage = e[:Links][:prev].do{|p|{_: :a, c: '&#9664;', rel: :prev, href: (CGI.escapeHTML p.to_s)}}
    nextPage = e[:Links][:next].do{|n|{_: :a, c: '&#9654;', rel: :next, href: (CGI.escapeHTML n.to_s)}}

    # massage JSON tree into HTML tree then call H to output characters
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:title].do{|t|{_: :title, c: CGI.escapeHTML(t)}},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 {_: :style, c: R['/css/base.css'].readFile},
                 {_: :style, c: "body, a  {background-color:#000;color:#fff}"},
                ]},
            {_: :body,
             c: [([{_: :a, id: :up, href: up, c: '&#9650;'},'<br clear=all>'] if up),
                 (prevPage && prevPage.merge({id: :prevpage})), (nextPage && nextPage.merge({id: :nextpage})),
                 graph.empty? ? {_: :span, style: 'font-size:8em', c: 404} : '',
                 graph.keys.grep(/\.(jpg|png)$/i).map{|img|
                   {_: :a, href: image, c: {_: :img, class: :thumb, src: image}}},
                 TabularView[graph,re],
                 {_: :script, c: R['/js/ui.js'].readFile},
                 {_: :style, c: e[:label].map{|name,_|
                        "[name=\"#{name}\"] {background-color: #{'#%06x' % (rand 16777216)}}\n"}},
                 '<br clear=all>',
                 (prevPage unless re.q.has_key? 'abbr'), (nextPage unless re.q.has_key? 'abbr'),
                 '<br clear=all>',expand]}]}]}
  
  # RDF types used in default view
  InlineMeta = [Mtime, Type, Title, Image, Content, Label]
  # RDF types collapsed in abbreviated view
  VerboseMeta = [DC+'identifier', DC+'link', DC+'source', DC+'hasFormat',
                 RSS+'comments', RSS+'em', RSS+'category',
                 Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',
                 SIOC+'has_discussion', SIOC+'reply_of', SIOC+'reply_to', SIOC+'num_replies', SIOC+'has_parent', SIOC+'attachment',
                 "http://wellformedweb.org/CommentAPI/commentRss","http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content"]

  TabularView = -> g, e {
    titles = {}
    # sorting attribute
    p = e.env[:sort]
    # sorting direction
    direction = e.q.has_key?('ascending') ? :id : :reverse
    # sorting datatype
    datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
    # columns
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    # show typetag first
    keys = [Type, *(keys - InlineMeta)]
    # abbreviate
    keys -= VerboseMeta unless e.q.has_key? 'full'
    # render
    [{_: :style, c: "[property=\"#{p}\"] {border-color:#eee;border-style: solid; border-width: 0 0 .1em 0}"},
     {_: :table,
     c: [{_: :tbody,
          c: g.values.sort_by{|s|
            ((if p == 'uri'
              s[Title] || s[Label] || s.uri
             else
               s[p]
              end).justArray[0]||0).send datatype}.send(direction).map{|r|
            TableRow[r,e,p,direction,keys,titles]}},
         {_: :tr, c: [keys.map{|k|
               q = e.q.merge({'sort' => k})
               if direction == :id
                 q.delete 'ascending'
               else
                 q['ascending'] = ''
               end
               href = CGI.escapeHTML R.qs q
               {_: :th, href: href, property: k, class: k == p ? 'selected' : '', c: {_: :a, href: href, class: Icons[k]||''}}}]}]}]}

#  View[Sound+'Player'] = -> g,e {
#    [{_: :script, type: "text/javascript", src: '/js/audio.js'},{_: :audio, id: :audio, controls: true}]}

  TableRow = -> l,e,sort,direction,keys,titles {
    this = l.R
    href = this.uri
    types = l.types
    monospace = types.member?(SIOC+'InstantMessage')||types.member?(SIOC+'MailMessage')
    isImg = types.member? Image
    fileResource = types.member?(Stat+'File') || types.member?(Container) || types.member?(Resource)
    shownActors = false
    title = l[Title].justArray.select{|t|t.class==String}[0].do{|t|
      t = t.sub ReExpr, ''
      titles[t] ? nil : (titles[t] = t)}

    actors = -> {
      shownActors ? '' : ((shownActors = true) && [[From,''],[To,'&rarr;']].map{|p,pl|
                            l[p].do{|o|
                              [{_: :b, c: pl + ' '},
                               o.justArray.uniq.map{|v|
                                 if v.respond_to?(:uri)
                                   v = v.R
                                   label = (v.fragment||(v.basename && v.basename.size > 1 && v.basename)||R.ungunk(v.host)).downcase.gsub(/[^a-zA-Z0-9_]/,'')
                                   e.env[:label][label] = true
                                   {_: :a, href: v.host == e.host ? (v.fragment ? v.dir.path : v.path) : v.uri, name: label, c: label, id: e.selector}
                                 else
                                   v.to_s
                                 end
                               }.intersperse(' '),' ']}})}

    [{_: :tr, href: href, id: e.selector,
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
                         unless %w{t.co tinyurl}.member? group
                           e.env[:label][group] = true
                           {name: group, class: :links,
                            c: [{_: :a, name: group, href: host ? ('//'+host) : '/', c: group}, ' ', links.map{|link|
                                  [{_: :a, href: link.uri, c: CGI.escapeHTML(link.uri)}.
                                     update(links.size < 9 ? {id: e.selector} : {}), ' ']}]}
                         end
                       }},
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
                   actors[]
                 when To
                   actors[]
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
     l[Image].do{|c|
       {_: :tr,
        c: [{_: :td},
            {_: :td, colspan: (keys.size - 1), c: c.justArray.map{|i|
               {_: :a, href: href, c: {_: :img, src: i.R.host == e.host ? i.R.path : i.uri, class: :preview}}}.intersperse(' ')}]}}]}

end
