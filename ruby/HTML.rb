# -*- coding: utf-8 -*-

def H x # Ruby to HTML
  case x
  when Hash
    void = [:img, :input, :link, :meta].member? x[:_]
    '<' + (x[:_] || 'div').to_s +                        # name
      (x.keys - [:_,:c]).map{|a|                         # attribute name
      ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
        {"'"=>'%27',
         '>'=>'%3E',
         '<'=>'%3C'}[c]||c}.join + "'"}.join +
      (void ? '/' : '') + '>' + (H x[:c]) +              # children or void
      (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # closer
  when R
    H x.href
  when String
    x
  when Symbol
    x.to_s
  when Array
    x.map{|n|H n}.join
  when Float
    x.to_s
  when Integer
    x.to_s
  when NilClass
    ''
  else
    x.to_s.noHTML
  end
end

class H

  def H.[] h; H h end

  def H.js a,inline=false # script tag
    p = a + '.js'
    inline ? {_: :script, c: p.R.r} :
    {_: :script, type: "text/javascript", src: p}
  end

  def H.css a,inline=false # stylesheet
    p = a + '.css'
    inline ? {_: :style, c: p.R.r} :
    {_: :link, href: p, rel: :stylesheet, type: R::MIME[:css]}
  end

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
    html.to_xhtml}

  Render['text/html'] = -> graph,re,view=nil {
    e = re.env
    dir = re.path[-1] == '/'
    groups = {}
    empty = graph.empty?
    graph.map{|u,r|
      r.types.map{|type|
        if v = View[type]
          groups[v] ||= {}
          groups[v][u] = r
          graph.delete u
        end}}
    e[:label] ||= {}
    up = if re.q.has_key? 'full'
           re.q.reject{|k|k=='full'}.merge({'abbr' => ''}).qs
         elsif dir && re.path != '/'
           re.justPath.dirname + '?' + re.env['QUERY_STRING']
         end
    print = re.q.has_key? 'print'
    (1..15).map{|i|e[:label]["quote"+i.to_s] = true}
    expand = {_: :a, id: :down, href: re.q.reject{|k|k=='abbr'}.merge({'full' => ''}).qs, class: :expand, c: "&#9660;"} if (dir || e[:glob]) && !re.q.has_key?('full')
    prevPage = e[:Links][:prev].do{|p|{_: :a, c: '&#9664;', rel: :prev, href: (CGI.escapeHTML p.to_s)}}
    nextPage = e[:Links][:next].do{|n|{_: :a, c: '&#9654;', rel: :next, href: (CGI.escapeHTML n.to_s)}}
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:title].do{|t|{_: :title, c: CGI.escapeHTML(t)}},
                 e[:Links].do{|links|
                   links.map{|type,uri|
                     {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 H.css('/css/base',true)]},
            {_: :body,
             c: [([{_: :a, id: :up, href: up, c: '&#9650;'},'<br clear=all>'] if up && !print),
                 (prevPage && prevPage.merge({id: :prevpage})),
                 (nextPage && nextPage.merge({id: :nextpage})),
                 empty ? {_: :span, style: 'font-size:8em', c: 404} : '',
                 groups.map{|view,graph|view[graph,re]},
                 (TabularView[graph,re] if graph.keys.size > 0),
                 {_: :style, c: e[:label].map{|name,_|"[name=\"#{name}\"] {background-color: #{'#%06x' % (rand 16777216)}}\n"}},
                 H.js('/js/ui',true),
                 '<br clear=all>',
                 (prevPage unless re.q.has_key? 'abbr'),
                 (nextPage unless re.q.has_key? 'abbr'),
                 '<br clear=all>',
                 expand,
                 {id: :statusbar}]}]}]}
  
  # properties in default view
  InlineMeta = [Mtime,Type,Title,Image,Content,Label]
  # hide unless verbose
  VerboseMeta = [DC+'identifier', DC+'link', DC+'source', DC+'hasFormat', RSS+'comments', RSS+'em', RSS+'category',
                 Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',
                 SIOC+'has_discussion', SIOC+'reply_of', SIOC+'reply_to', SIOC+'num_replies', SIOC+'has_parent', SIOC+'attachment',
  "http://wellformedweb.org/CommentAPI/commentRss","http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content"]
  
  TabularView = -> g, e, show_head = true, show_id = true {
    sort = (e.q['sort']||'dc:date').expand
    direction = e.q.has_key?('ascending') ? :id : :reverse

    # show typetag first, hide inlined columns
    keys = g.values.select{|v|v.respond_to? :keys}.map(&:keys).flatten.uniq
    keys = [Type, *(keys - InlineMeta)]
    keys -= VerboseMeta unless e.q.has_key? 'full'

    {_: :table,
     c: [{_: :tbody, c: g.resources(e).map{|r| TableRow[r,e,sort,direction,keys] }},
         {_: :tr, c: [keys.map{|k|
               q = e.q.merge({'sort' => k.shorten})
               if direction == :id
                 q.delete 'ascending'
               else
                 q['ascending'] = ''
               end
               href = CGI.escapeHTML q.qs
               [{_: :th, href: href, property: k,
                 class: k == sort ? 'selected' : '',
                 c: {_: :a, href: href, class: Icons[k]||''}}, "\n"]}]}]}}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    href = this.host == e.host ? this.path : this.uri
    types = l.types
    monospace = types.member?(SIOC+'InstantMessage')||types.member?(SIOC+'MailMessage')
    isImg = types.member? Image
    shownActors = false

    actors = -> {
      shownActors ? '' : ((shownActors = true) && [[From,''],[To,'&rarr;']].map{|p,pl|
        l[p].do{|o|
          [{_: :b, c: pl + ' '},
           o.justArray.map{|v|
             if v.respond_to?(:uri)
               v = v.R
               label = (v.fragment||v.basename && v.basename.size > 1 && v.basename || v.host.split('.')[0..-2].join).downcase.gsub(/[^a-zA-Z0-9_]/,'')
               e.env[:label][label] = true
               {_: :a, href: v.host == e.host ? v.path : v.uri, name: label, c: label}
             else
               v.to_s
             end
           }.intersperse(' '),' ']}})}

    [{_: :tr, class: :selectable, href: href, id: e.selector,
       c: ["\n",
           keys.map{|k|
             [{_: :td, property: k, class: sort==k ? 'selected' : '',
               c: case k
                  when 'uri' # URI, Title, body + attachment fields shown here to reduce column-bloat
                    title = l[Title].justArray[0]
                    [# labels
                      l[Label].justArray.map{|v|
                        label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                        lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                        e.env[:label][lbl] = true
                        [{_: :a, href: href, name: lbl, c: label},' ']},
                      # Title
                      {_: :a, class: title ? :title : (e.path==this.path ? :this : :uri), href: href, c: CGI.escapeHTML(title ? title : (this.fragment||this.basename))},
                      (title ? '<br>' : ' '),
                      # links
                      {class: :files,
                       c: [DC+'link', SIOC+'attachment',
                           DC+'hasFormat'].map{|p|
                         l[p].justArray.map{|link|
                           link = link.R
                           [{_: :a, class: :link, id: e.selector, href: link.uri,
                             c: CGI.escapeHTML(link.fragment||link.basename=='/' ? link.host : link.basename)},
                            ' ']}}},
                      # body
                      l[Content].justArray.map{|c| monospace ? {_: :pre, c: c} : c },
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
                   l[Type].justArray.map{|t|
                     icon = Icons[t.uri]
                     {_: :a, href: href, c: icon ? '' : (t.R.fragment||t.R.basename), class: icon}}
                 when LDP+'contains'
                   l[k].do{|children|
                     children = children.justArray
                     if children[0].keys.size > 1 # tabular-view of contained children
                       childGraph = {}
                       children.map{|c|childGraph[c.uri] = c}
                       TabularView[childGraph,e,false]
                      else
                       children.map{|c|[(CGI.escapeHTML c.R.basename[0..15]), ' ']}
                     end}
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
