#watch __FILE__
class R

  # traversible blog-post collection
  # to mount on a site-root  GET['http://site/'] = GET['/blog']
  GET['/blog'] = -> d,e {
    if %w{/ /blog}.member? d.pathSegment
      e.q['set'] = 'depth' # post-range in date-order
      e.q['local'] = true  # hostname-specific
      e.q['c'] ||= 8       # page size
    R['http://'+e['SERVER_NAME']+'/blog'].setEnv(e).response
    end}

  # prompt for title of new post
  GET['/blog/post'] = -> d,e {
    [200,{'Content-Type'=>'text/html'},
     [H(['title',
         {_: :form, method: :POST,
           c: [{_: :input, name: :title, style: "font-size:1.6em;width:48ex"},
               {_: :input, type: :submit, value: ' go '}
              ]}])]]}

  # mint URI (date and name), insert title+type to db, forward to default editor
  POST['/blog/post'] = -> d,e {
    host = 'http://' + e['SERVER_NAME']
    title = (Rack::Request.new d.env).params['title'] # decode POST-ed title
    base = R[host+Time.now.strftime('/%Y/%m/%d/')+URI.escape(title.gsub /[?#\s\/]/,'_')] # doc URI
    post = base.a '#'                # resource URI
    post[Type] = R[SIOCt+'BlogPost'] # add SIOC post-type
    post[Title] = title              # add Title
    post.snapshot
    base.jsonDoc.ln_s R[host + '/blog/' + Time.now.iso8601[0..18].gsub('-','/') + '.e'] # datetime-index
    [303,{'Location' => (base+"?prototype=sioct:BlogPost&view=edit&mono").uri},[]]}

  View[SIOCt+'BlogPost'] = -> g,e {
    g.map{|u,r|
      {class: :blogpost, c: [{_: :a, href: u, c: {_: :h1, c: r[Title]}}, r[Content]]}
    }}

  View[SIOCt+'MicroblogPost'] = -> d,e {
    [(H.once e,'chat',(H.css '/css/tw'),{_: :style, c: "body {background-color: #{R.c}}"}),
     d.map{|u,r|
       r[Content] && r[Date]
       [r[Date].justArray[0].match(/T([0-9:]{5})/).do{|m|m[1]},
        {_: :span, :class => :nick, c: {_: :a, href: r.uri, id: r.uri.split('#')[-1],
            c: [r[Atom+"/link/image"].do{|p|{_: :img, src: p[0].uri, style: "#{rand(2).zero? ? 'left' : 'right'}: 0"}},
                {_: :span, c: r[Creator].do{|c|
                    c[0].respond_to?(:uri) ? c[0].uri.abbrURI : c[0].to_s}}]}},' ',
        {_: :span, :class => :tw, c: r[Content]},"<br>\n"]}]}

  View[SIOCt+'InstantMessage'] = View[SIOCt+'MicroblogPost']

  def triplrIRC &f
    i=-1
    day = dirname.uri.split('/')[-3..-1].do{|dp|
      dp.join('-') if dp[0].match(/^\d{4}$/)
    }||''
    doc = uri.gsub '#','%23'
    channel = bare
    r.lines.map{|l|
#19:10 [    kludge] _abc_: because people discovered that APL was totally unmaintainable.  People wrote code and then went to lunch and when they came back they couldn't figure out what the hell they had done.
#19:10 [     _abc_] Sounds like Perl
      l.scan(/(\d\d):(\d\d) \[[\s@]*([^\(\]]+)[^\]]*\] (.*)/){|m|
        s = doc + '#' + doc + ':' + (i+=1).to_s
        yield s, Date,                day+'T'+m[0]+':'+m[1]+':00'
        yield s, SIOCt+'ChatChannel', channel
        yield s, Creator,             m[2]
        yield s, Content,             m[3].hrefs(true)
        yield s, Type,                R[SIOCt+'InstantMessage']
        yield s, Type,                R[SIOC+'Post']
        yield s, SIOC+'link',        (m[3].match(/http:\//) ? 'true' : 'false')
      } rescue nil
    }
  end

  def tw g
    node.readlines.shuffle.each_slice(22){|s|
      R['https://twitter.com/search/realtime?q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].addDocsJSON :triplrTwMsg, g, nil, FeedArchiverJSON}
  end

  def triplrTwUser
    open(d).readlines.map{|l|
      yield 'https://twitter.com/'+l.chomp, '/rev', self}
  end

  def triplrTwMsg
    base = 'http://twitter.com'
    nokogiri.css('div.tweet').map{|t|
      s = base + t.css('a.details').attr('href') # subject URI
      yield s, Type, R[SIOCt+'MicroblogPost']
      yield s, Type, R[SIOC+'Post']
      yield s, Creator, R(base+'/'+t.css('.username b')[0].inner_text)
      yield s, Name,t.css('.fullname')[0].inner_text
      yield s, Atom+"/link/image", R(t.css('.avatar')[0].attr('src'))
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a|
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, content.inner_html
    }
  end

end
