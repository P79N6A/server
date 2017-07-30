# coding: utf-8
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

class String
  def R; R.new self end
  # scan for HTTP URIs in string. example:
  # as you can see in the demo (https://suchlike) and find full source at https://stuffshere.com.

  # these decisions were made:
  #  opening ( required for ) match, as referencing URLs inside () seems more common than URLs containing unmatched ()s [citation needed]
  #  , and . only match mid-URI to allow usage of URIs as words in sentences ending in a period.
  # <> wrapping is stripped
  def hrefs &b
    pre,link,post = self.partition /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escape URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escape pre-match
      (link.empty? && '' || '<a href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # emit image
        "<img src='#{u}'/>"           # inline image
       else
         yield(R::DC+'link',u.R) if b # emit link
         u.sub(/^https?.../,'')       # innertext
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # process post-match tail
  rescue Exception => x
    puts [x.class,x.message,self[0..127]].join(" ")
    ""
  end
  def sha1; Digest::SHA1.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end

class R

  def href name=nil; {_: :a, href: uri, c: name || fragment || basename} end
  def nokogiri; Nokogiri::HTML.parse (open uri).read end
  def R.ungunk host; (host||'').sub(/^www./,'').sub(/\.(com|edu|net|org)$/,'') end

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove} if loseTags
    html.traverse{|e|
      e.attribute_nodes.map{|a|
        a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml(:indent => 0)}

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

  # 1 translate graph-in-JSON to HTML-in-Ruby
  # 2 translate HTML-in-Ruby to HTML
  HTML = -> graph, re {
    e = re.env
    Grep[graph,re] if re.q.has_key?('q') && !re.q.has_key?('full')
    upPage = e[:Links][:up].do{|u|[{_: :a, c: '&#9650;', rel: :up, href: (CGI.escapeHTML u.to_s)},'<br clear=all>']}
    prevPage = e[:Links][:prev].do{|p|{_: :a, c: '&#9664;', rel: :prev, href: (CGI.escapeHTML p.to_s)}}
    nextPage = e[:Links][:next].do{|n|{_: :a, c: '&#9654;', rel: :next, href: (CGI.escapeHTML n.to_s)}}
    downPage = e[:Links][:down].do{|d|['<br clear=all>',{_: :a, c: '&#9660;', rel: :down, href: (CGI.escapeHTML d.to_s)}]}
    template = re.q.has_key?('gallery') ? Gallery : TabularView
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 e[:Links].do{|links|links.map{|type,uri|{_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 {_: :script, c: R['/js/ui.js'].readFile},{_: :style, c: R['/css/base.css'].readFile}]},
            {_: :body,
             c: [upPage, prevPage, nextPage, template[graph,re], ({_: :span,style: 'font-size:8em',c: 404} if graph.empty?), ([prevPage,nextPage] if graph.keys.size > 12), downPage]}]}]} # view and pagination links

  # arc-types not mapped to columns
  InlineMeta = [Title, Image, Content, Label]
  # arc-types hidden in overview
  VerboseMeta = [DC+'identifier', DC+'link', DC+'source', DC+'hasFormat', DCe+'rights', DCe+'publisher', RSS+'comments', RSS+'em', RSS+'category', Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',SIOC+'has_discussion', SIOC+'reply_of', SIOC+'reply_to', SIOC+'num_replies', SIOC+'has_parent', SIOC+'attachment', Mtime, Podcast+'explicit', Podcast+'summary', "http://wellformedweb.org/CommentAPI/commentRss","http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content",Harvard+'featured']

  TabularView = -> g, e {
    e.env[:label] = {}
    (1..10).map{|i|
      e.env[:label]["quote"+i.to_s] = true}
    # sort field
    p = e.q['sort'] || Date
    # sort direction
    direction = e.q.has_key?('ascending') ? :id : :reverse
    # sort datatype
    datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
    # column heading
    keys = [Type, g.values.select{|v|v.respond_to? :keys}.map(&:keys)].flatten.uniq
    keys -= InlineMeta
    keys -= VerboseMeta unless e.q.has_key? 'full'
    [{_: :table,
      c: [{_: :tbody,
           c: g.values.sort_by{|s|
             ((if p == 'uri'
               s[Title] || s[Label] || s.uri
              else
                s[p]
               end).justArray[0]||0).send datatype}.send(direction).map{|r|TableRow[r,e,p,direction,keys]}},
          {_: :tr, c: keys.map{|k|
             q = e.q.merge({'sort' => k})
             if direction == :id
               q.delete 'ascending'
             else
               q['ascending'] = ''
             end
             href = CGI.escapeHTML R.qs q
             {_: :th, href: href, property: k, class: k == p ? 'selected' : '',
              c: {_: :a, href: href, class: Icons[k] || '', c: Icons[k] ? '' : (k.R.fragment||k.R.basename)}}}}]},
     {_: :style, c: e.env[:label].map{|name,_| "[name=\"#{name}\"] {background-color: #{'#%06x' % (rand 16777216)}}\n"}}, # color-label CSS
     {_: :style, c: "[property=\"#{p}\"] {border-color:#999;border-style: solid; border-width: 0 0 .1em 0}"}]} # sorting-property CSS

  Gallery = -> graph,e,_=true {
    images = graph.keys.grep /(jpg|png)$/i
    {_: :html,
     c: [{_: :head,
          c: [{_: :style, c: R['/css/photo.css'].readFile},{_: :style, c: R['/css/misc/default-skin.css'].readFile},{_: :script, c: R['/js/photoswipe.min.js'].readFile},{_: :script, c: R['/js/photoswipe-ui.min.js'].readFile}]},
         {_: :body,
          c: [images.map{|i|
                {_: :a, class: :thumb, id: 'a'+rand.to_s.sha1[0..7], href: i, c: {_: :img, src: i+'?thumb', style: 'height:20em'}}},
              %q{<!-- Root element of PhotoSwipe. Must have class pswp. --> <div class="pswp" tabindex="-1" role="dialog" aria-hidden="true"> <!-- Background of PhotoSwipe.          It's a separate element as animating opacity is faster than rgba(). --> <div class="pswp__bg"></div> <!-- Slides wrapper with overflow:hidden. --> <div class="pswp__scroll-wrap"> <!-- Container that holds slides.             PhotoSwipe keeps only 3 of them in the DOM to save memory.             Don't modify these 3 pswp__item elements, data is added later on. --> <div class="pswp__container"> <div class="pswp__item"></div> <div class="pswp__item"></div> <div class="pswp__item"></div> </div> <!-- Default (PhotoSwipeUI_Default) interface on top of sliding area. Can be changed. --> <div class="pswp__ui pswp__ui--hidden"> <div class="pswp__top-bar"> <!--  Controls are self-explanatory. Order can be changed. --> <div class="pswp__counter"></div> <button class="pswp__button pswp__button--close" title="Close (Esc)"></button> <button class="pswp__button pswp__button--share" title="Share"></button> <button class="pswp__button pswp__button--fs" title="Toggle fullscreen"></button> <button class="pswp__button pswp__button--zoom" title="Zoom in/out"></button> <!-- Preloader demo http://codepen.io/dimsemenov/pen/yyBWoR --> <!-- element will get class pswp__preloader--active when preloader is running --> <div class="pswp__preloader"> <div class="pswp__preloader__icn"> <div class="pswp__preloader__cut"> <div class="pswp__preloader__donut"></div> </div> </div> </div> </div> <div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap"> <div class="pswp__share-tooltip"></div> </div> <button class="pswp__button pswp__button--arrow--left" title="Previous (arrow left)"> </button> <button class="pswp__button pswp__button--arrow--right" title="Next (arrow right)"> </button> <div class="pswp__caption"> <div class="pswp__caption__center"></div> </div> </div> </div> </div>},
              {_: :script, c: "
      var items = #{images.map{|k|{src: k, w: graph[k][Stat+'width'].justArray[0].to_i, h: graph[k][Stat+'height'].justArray[0].to_i}}.to_json};
//      var gallery = new PhotoSwipe( document.querySelectorAll('.pswp')[0], PhotoSwipeUI_Default, items, {index: 0});
//      gallery.init();
"}]}]}}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    href = this.uri
    types = l.types
    # node-identifier for selection ring
    rowID = if e.path[-1]=='/' # container and multiple docs: mint new identifier
              e.selector
            else # document fragment, if exists
              this.fragment || e.selector
            end
    abbr = e.q.has_key? 'abbr'
    monospace = types.member?(SIOC+'InstantMessage')||types.member?(SIOC+'MailMessage')
    isImg = types.member? Image

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

    [{_: :tr, href: href, id: rowID, class: (this.path==e.path && this.path[-1]=='/') ? 'here' : 'elsewhere',
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
                     (if titles = l[Title]
                      titles.justArray.map{|title|
                        {_: :a, class: :title, href: href, c: (CGI.escapeHTML title.to_s.sub(ReExpr,''))}}.intersperse(' ')
                     elsif !types.member?(SIOC+'InstantMessage') && !types.member?(SIOC+'Tweet')
                       name = this.path || ''
                       {_: :a, href: href, c: (CGI.escapeHTML (URI.unescape (File.basename name)))}
                      end),
                     # links
                     ([DC+'link', SIOC+'attachment', DC+'hasFormat'].map{|p|
                       l[p].justArray.map(&:R).group_by(&:host).map{|host,links|
                         group = R.ungunk (host||'')
                         e.env[:label][group] = true
                         {name: group, class: :links,
                          c: [{_: :a, name: group, href: host ? ('//'+host) : '/', c: group}, ' ', links.map{|link|
                                [{_: :a, href: link.uri, c: CGI.escapeHTML((link.path||'')[1..-1]||'')}.
                                   update(links.size < 9 ? {id: e.selector} : {}), ' ']}]}}} unless abbr),
                     # body
                     (l[Content].justArray.map{|c|monospace ? {_: :pre,c: c} : c} unless abbr),
                     # images
                     (['<br>', {_: :a, href: href,
                                c: {_: :img,
                                    src: if !this.host || e.host==this.host # local image thumbnail
                                     this.path + '?thumb'
                                   else
                                     this.uri
                                    end}}] if isImg)]
                 when Type
                   l[Type].justArray.uniq.map{|t|
                     if t.respond_to? :uri
                       icon = Icons[t.uri]
                       {_: :a, href: href, c: icon ? '' : (t.R.fragment||t.R.basename), class: icon}
                     end
                   }
                 when Schema+'logo'
                   l[k].justArray.map{|logo|
                     if logo.respond_to? :uri
                       {_: :a, href: l[DC+'link'].justArray[0].do{|l|l.uri}||'#',
                        c: {_: :img, class: :logo, src: logo.uri}}
                     end
                   }
                 when From
                   actors[From]
                 when To
                   actors[To]
                 when Size
                   l[Size].do{|sz|
                     sum = 0
                     sz.justArray.map{|v|
                       sum += v.to_i}
                     sum}
                 when Date
                   l[Date].justArray.map{|v|
                     {_: :span, class: :date, c: v}
                   }.intersperse(' ')
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
