# coding: utf-8
def H x # data to HTML
  case x
  when String
    x
  when Hash # element
    void = [:img, :input, :link, :meta].member? x[:_]
    '<' + (x[:_] || 'div').to_s +                        # element name
      (x.keys - [:_,:c]).map{|a|                         # attribute name
      ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
        {"'"=>'%27', '>'=>'%3E',
         '<'=>'%3C'}[c]||c}.join + "'"}.join +
      (void ? '/' : '') + '>' + (H x[:c]) +              # children
      (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # element closer
  when Array # sequential structure
    x.map{|n|H n}.join
  when R # <a>
    H({_: :a, href: x.uri, c: x.label})
  when NilClass
    ''
  else
    CGI.escapeHTML x.to_s
  end
end

class String
  def R; R.new self end
  # scan for HTTP URIs in string. example:
  # demo on the site (https://demohere) and source-code at https://sourcehere.
  # [,.] only match mid-URI, opening ( required for ) capture, <> wrapping is stripped
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
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end

class R

  def nokogiri; Nokogiri::HTML.parse (open uri).read end

  StripHTML = -> body, loseTags=%w{iframe script style}, keepAttr=%w{alt href rel src title type} {
    html = Nokogiri::HTML.fragment body
    loseTags.map{|tag| html.css(tag).remove} if loseTags
    html.traverse{|e|
      e.attribute_nodes.map{|a|
        a.unlink unless keepAttr.member? a.name}} if keepAttr
    html.to_xhtml(:indent => 0)}

  Grep = -> graph, q {
    wordIndex = {}
    words = q.scan(/[\w]+/).map(&:downcase).uniq
    words.each_with_index{|word,i|wordIndex[word]=i}
    pattern = /#{words.join '.*'}/i
    highlight = /(#{words.join '|'})/i
    graph.map{|u,r|
      r.values.flatten.select{|v|v.class==String}.map(&:lines).flatten.map{|l|l.gsub(/<[^>]+>/,'')}.grep(pattern).do{|lines|
        r[Content] = []
        lines[0..5].map{|line|
          r[Content].unshift line[0..400].gsub(highlight){|g|
            H({_: :span, class: "w w#{wordIndex[g.downcase]}", c: g})}}}
      graph.delete u if r[Content].empty?} 
    graph['#grep.CSS'] = {Content => H({_: :style, c: wordIndex.values.map{|i|".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}}

  HTML = -> graph, re { e=re.env
    e[:title] = graph[re.path+'#this'].do{|r|r[Title].justArray[0]}
    re.q['q'].do{|q|Grep[graph,q]}
    # tree-graph -> HTML-Ruby -> HTML-String
    upPage = e[:Links][:up].do{|u|[{_: :a, c: '&#9650;', id: :Up, rel: :up, href: (CGI.escapeHTML u.to_s)},'<br clear=all>']} unless re.path=='/'
    prevPage = e[:Links][:prev].do{|p|{_: :a, c: '&#9664;', rel: :prev, href: (CGI.escapeHTML p.to_s)}}
    nextPage = e[:Links][:next].do{|n|{_: :a, c: '&#9654;', rel: :next, href: (CGI.escapeHTML n.to_s)}}
    downPage = e[:Links][:down].do{|d|['<br clear=all>',{_: :a, c: '&#9660;', id: :Down, rel: :down, href: (CGI.escapeHTML d.to_s)}]}
    images = graph.keys.grep /(jpg|png)$/i
    template = images.size==graph.keys.size ? Gallery : TabularView
    H ["<!DOCTYPE html>\n",
       {_: :html,
        c: [{_: :head,
             c: [{_: :meta, charset: 'utf-8'},
                 {_: :link, rel: :icon, href: '/.icon.png'},
                 {_: :title, c: e[:title]||re.path},
                 e[:Links].do{|links|links.map{|type,uri| {_: :link, rel: type, href: CGI.escapeHTML(uri.to_s)}}},
                 {_: :script, c: R['/js/ui.js'].readFile}, {_: :style, c: R['/css/base.css'].readFile}]},
            {_: :body,
             c: [upPage, prevPage, nextPage, # page links
                 template[graph,re],
                 ([{_: :style, c: "body {text-align:center;background-color:##{'%06x' % (rand 16777216)}}"},
                   {_: :span,style: 'font-size:12em;font-weight:bold',c: 404}] if graph.empty?),
                 ([prevPage,nextPage] if graph.keys.size > 8), downPage]}]}]}

  InlineMeta = [Title, Image, Content, Label, DC+'hasFormat', DC+'link', SIOC+'attachment', SIOC+'user_agent', Stat+'contains']
  VerboseMeta = [DC+'identifier', DC+'source', DCe+'rights', DCe+'publisher', RSS+'comments', RSS+'em', RSS+'category', Atom+'edit', Atom+'self', Atom+'replies', Atom+'alternate',SIOC+'has_discussion', SIOC+'reply_of', SIOC+'num_replies', Mtime, Podcast+'explicit', Podcast+'summary', "http://wellformedweb.org/CommentAPI/commentRss","http://rssnamespace.org/feedburner/ext/1.0#origLink","http://purl.org/syndication/thread/1.0#total","http://search.yahoo.com/mrss/content",Harvard+'featured']
  TabularView = -> g, e {
    e.env[:label] = {}; (1..10).map{|i|e.env[:label]["quote"+i.to_s] = true} # colorize up to 10-levels of quoting
    [:links,:images].map{|p| e.env[p] = []} # link and image lists for deduplication
    p = e.q['sort'] || Date
    direction = e.q.has_key?('ascending') ? :id : :reverse
    datatype = [R::Size,R::Stat+'mtime'].member?(p) ? :to_i : :to_s
    keys = ['uri', Type, g.values.select{|v|v.respond_to? :keys}.map(&:keys)].flatten.uniq
    keys -= InlineMeta; keys -= VerboseMeta unless e.q.has_key? 'full'
    [{_: :table,
      c: [{_: :tbody,
           c: g.values.sort_by{|s|
             ((if p == 'uri'
               s[Title] || s[Label] || s.uri
              else
                s[p]
               end).justArray[0]||0).send datatype}.send(direction).map{|r| # sort rows
             TableRow[r,e,p,direction,keys]}.intersperse("\n")},          # render row
          {_: :tr, c: keys.map{|k| # header row
             q = e.q.merge({'sort' => k})
             if direction == :id # direction toggle
               q.delete 'ascending'
             else
               q['ascending'] = ''
             end
             href = CGI.escapeHTML R.qs q
             {_: :th,href: href,property: k,class: k==p ? 'selected' : '',c: {_: :a,href: href,class: Icons[k]||'',c: Icons[k] ? '' : (k.R.fragment||k.R.basename)}}}}]},
     {_: :style, c: ".focus, .focus a {background-color:##{'%06x' % (rand 16777216)};color:#fff;font-size:1.2em}\n"},
     {_: :style, c: e.env[:label].map{|name,_| "[name=\"#{name}\"] {color:#000;background-color: #{'#%06x' % (rand 16777216)}}\n"}},
     {_: :style, c: "[property=\"#{p}\"] {border-color:#999;border-style: solid; border-width: 0 0 .1em 0}"}]}

  Gallery = -> graph,e,_=true {
    [{_: :style, c: R['/css/photo.css'].readFile},
     {_: :style, c: R['/css/misc/default-skin.css'].readFile},
     {_: :script, c: R['/js/photoswipe.min.js'].readFile},
     {_: :script, c: R['/js/photoswipe-ui.min.js'].readFile},
     graph.keys.map{|i|
       {_: :a, class: :thumb, id: 'a'+rand.to_s.sha2[0..7], href: i.R.basename, c: {_: :img, src: i.R.thumb.basename}}},
     %q{<!-- Root element of PhotoSwipe. Must have class pswp. --> <div class="pswp" tabindex="-1" role="dialog" aria-hidden="true"> <!-- Background of PhotoSwipe.          It's a separate element as animating opacity is faster than rgba(). --> <div class="pswp__bg"></div> <!-- Slides wrapper with overflow:hidden. --> <div class="pswp__scroll-wrap"> <!-- Container that holds slides.             PhotoSwipe keeps only 3 of them in the DOM to save memory.             Don't modify these 3 pswp__item elements, data is added later on. --> <div class="pswp__container"> <div class="pswp__item"></div> <div class="pswp__item"></div> <div class="pswp__item"></div> </div> <!-- Default (PhotoSwipeUI_Default) interface on top of sliding area. Can be changed. --> <div class="pswp__ui pswp__ui--hidden"> <div class="pswp__top-bar"> <!--  Controls are self-explanatory. Order can be changed. --> <div class="pswp__counter"></div> <button class="pswp__button pswp__button--close" title="Close (Esc)"></button> <button class="pswp__button pswp__button--share" title="Share"></button> <button class="pswp__button pswp__button--fs" title="Toggle fullscreen"></button> <button class="pswp__button pswp__button--zoom" title="Zoom in/out"></button> <!-- Preloader demo http://codepen.io/dimsemenov/pen/yyBWoR --> <!-- element will get class pswp__preloader--active when preloader is running --> <div class="pswp__preloader"> <div class="pswp__preloader__icn"> <div class="pswp__preloader__cut"> <div class="pswp__preloader__donut"></div> </div> </div> </div> </div> <div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap"> <div class="pswp__share-tooltip"></div> </div> <button class="pswp__button pswp__button--arrow--left" title="Previous (arrow left)"> </button> <button class="pswp__button pswp__button--arrow--right" title="Next (arrow right)"> </button> <div class="pswp__caption"> <div class="pswp__caption__center"></div> </div> </div> </div> </div>},
     {_: :script, c: "
      var items = #{graph.keys.map{|k|{src: k.R.basename, msrc: k.R.thumb.basename, w: graph[k][Stat+'width'][0], h: graph[k][Stat+'height'][0]}}.to_json};
      var gallery = new PhotoSwipe( document.querySelectorAll('.pswp')[0], PhotoSwipeUI_Default, items, {index: #{e.q['start']||0}});
      gallery.init();
"}]}

  TableRow = -> l,e,sort,direction,keys {
    this = l.R
    href = this.uri
    head = e.q.has_key? 'head'
    types = l.types
    focus = !this.fragment && this.path==e.path
    monospace = types.member?(SIOC+'InstantMessage') || types.member?(SIOC+'MailMessage')
    rowID = if e.path == this.path && this.fragment
              this.fragment
            else
              'row_' + href.sha2
            end
    names = []
    # explicit title
    l[Title].do{|t|
      names.concat t.justArray}
    # name from fs metadata
    unless !names.empty? || !this.path || types.member?(SIOC+'Tweet') || monospace
      fsName = (URI.unescape (File.basename this.path))[0..64]
      names.push(focus && e.env[:title] || fsName)
    end
    isImg = types.member? Image
    show = !head || !names.empty?
    if show
      {_: :tr, href: href, class: focus ? 'focus' : '',
       c: keys.map{|k|
         {_: :td, property: k,
          c: case k
             when 'uri'
               # names
               [names.map{|name|{_: :a, class: :title, href: href, c: (CGI.escapeHTML name.to_s)}}.intersperse(' '), ' ',
                # labels
                l[Label].justArray.map{|v|
                  label = (v.respond_to?(:uri) ? (v.R.fragment || v.R.basename) : v).to_s
                  lbl = label.downcase.gsub(/[^a-zA-Z0-9_]/,'')
                  e.env[:label][lbl] = true
                  [{_: :a, class: :label, href: href, name: lbl, c: (CGI.escapeHTML label)},' ']},
                # containment
                (l[Stat+'contains'].justArray.sort_by(&:uri).do{|cs|
                  {class: :containers, c: cs.map{|c|{_: :a, href: c.uri, c: c.label+' '}.update(focus ? {id: 'c_'+c.uri.sha2} : {})}} unless cs.empty?} unless focus),
                # links
                (links = [DC+'link',
                          SIOC+'attachment',
                          DC+'hasFormat'].map{|p|l[p]}.flatten.compact.map(&:R).select{|l|!e.env[:links].member? (l.host||'')+(l.path||'')} # unseen links (strip query)
                 links.map{|l|e.env[:links].push (l.host||'')+(l.path||'')} # mark as visited
                 {_: :table, class: :links, # show
                  c: links.group_by(&:host).map{|host,links|
                    e.env[:label][host] = true
                    small = links.size < 5
                    {_: :tr,
                     c: [{_: :td, class: :host, c: ({_: :a, name: host, href: '//'+host, c: host.sub(/^www\./,'')} if host)},
                         {_: :td, class: :path, c: links.map{|link|
                            [{_: :a, name: host, href: link.uri, c: CGI.escapeHTML(link.label[0..64])}.update(small ? {id: 'link_'+rand.to_s.sha2} : {}), ' ']}}]}}} unless links.empty?),
                (l[Content].justArray.map{|c|monospace ? {_: :pre,c: c} : c} unless head),
                # images
                (images = [] # image list
                 images.push this if isImg       # subject of triple
                 l[Image].do{|i|images.concat i} #  object of triple
                 images.map(&:R).select{|i|!e.env[:images].member? i}.map{|img| # unseen images
                   e.env[:images].push img
                   {_: :a, class: :thumb, href: href,
                    c: {_: :img, src: if !img.host || e.host==img.host
                         img.path + '?thumb'
                       else
                         img.uri
                        end}}})]
             when Type
               l[Type].justArray.uniq.select{|t|t.respond_to? :uri}.map{|t|
                 {_: :a, href: href, c: Icons[t.uri] ? '' : (t.R.fragment||t.R.basename), class: Icons[t.uri]}}
             when Size
               l[Size].do{|sz|
                 sum = 0
                 sz.justArray.map{|v|
                   sum += v.to_i}
                 sum}
             when Creator
               [l[k].justArray.map{|v|
                 if v.respond_to? :uri
                   v = v.R
                   v.host ? v : {_: :a, href: v.path + '?head#row_' + href.sha2, c: v.label} if v.path
                 else
                   CGI.escapeHTML v.to_s
                 end}.intersperse(' '),
                (l[SIOC+'user_agent'].do{|ua|['<br>',{_: :span, class: :notes, c: ua.join}]} unless head)]
             when SIOC+'addressed_to'
               l[k].justArray.map{|v|
                 if v.respond_to? :uri
                   v = v.R
                   v.host ? v : {_: :a, href: v.path + '?head#row_' + href.sha2, c: v.label}
                 else
                   CGI.escapeHTML v.to_s
                 end}.intersperse(' ')
             when Date
               l[Date].justArray.sort[-1].do{|v|
                 {_: :a, class: :date, href: '/'+v[0..13].gsub(/[-T:]/,'/')+'#row_'+href.sha2, c: v}}
             when DC+'cache'
               l[k].justArray.map{|c|[{_: :a, href: c.path, c: '&#9939;'}, ' ']}
             else
               l[k].justArray.map{|v|v.respond_to?(:uri) ? v.R : CGI.escapeHTML(v.to_s)}.intersperse(' ')
             end}}.intersperse("\n")}.update(focus ? {} : {id: rowID})
    end
  }

end
