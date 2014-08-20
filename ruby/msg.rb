class R

  View[SIOCt+'MicroblogPost'] = -> d,e {
    c = R.c # color
    [(H.once e,'chat',(H.css '/css/tw'),{_: :style,c: "body {background-color: #{c}}"}),
     d.map{|u,r|
       r[Content] && r[Date]
       [r[Date].justArray[0].match(/T([0-9:]{5})/).do{|m|m[1]},
        {_: :a, class: :author, href: r.uri, c: r[Creator].do{|c|
            c[0].respond_to?(:uri) ? c[0].R.abbr : c[0].to_s}},' ',
        {class: :tw, c: r[Content]},"<br>\n"]}]}

  View[SIOCt+'InstantMessage'] = View[SIOCt+'MicroblogPost']

  def triplrIRC &f
    i=-1
    day = dirname.split('/')[-3..-1].do{|dp|
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
      } rescue nil
    }
  end

  def tw g
    node.readlines.shuffle.each_slice(22){|s|
      R['https://twitter.com/search/realtime?q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].triplrCacheJSON :triplrTwMsg, g, nil, FeedArchiverJSON}
  end

  def triplrTwUser
    yield uri, Type, R[COGS+'UriList']
    open(d).readlines.map{|l|
      u = 'https://twitter.com/' + l.chomp
      yield uri, '/rel', u.R
      yield u, '/rev', self
      yield u, Type, R[CSVns+'Row']}
  end

  def triplrTwMsg
    base = 'https://twitter.com'
    nokogiri.css('div.tweet').map{|t|
      s = base + t.css('a.details').attr('href') # subject URI
      yield s, Type, R[SIOCt+'MicroblogPost']
      yield s, Type, R[SIOC+'Post']
      yield s, Creator, R(base+'/'+t.css('.username b')[0].inner_text)
      yield s, Name, t.css('.fullname')[0].inner_text
      yield s, Atom+"/link/image", R(t.css('.avatar')[0].attr('src'))
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a|
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, CleanHTML[content.inner_html]
    }
  end

end
