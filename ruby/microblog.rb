#watch __FILE__
class R

  def triplrIRC &f
    i=-1
    day = dirname.uri.split('/')[-3..-1].do{|dp|
      dp.join('-') if dp[0].match(/^\d{4}$/)
    }||''
    doc = uri.gsub '#','%23'
    channel = bare
    r.lines.map{|l|
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
      R['https://twitter.com/search/realtime?q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].addDocsJSON :triplrTweets, g, nil, FeedArchiverJSON}
  end

  def triplrTweets
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

  fn 'view/chat',->d,e{
    [(H.once e,'chat',(H.css '/css/tw'),{_: :style, c: "body {background-color: #{R.c}}"}),
     d.map{|u,r|
       r[Content] && r[Date]
       [r[Date].justArray[0].match(/T([0-9:]{5})/).do{|m|m[1]},
        {_: :span, :class => :nick, c: {_: :a, href: r.uri,
            c: [r[Atom+"/link/image"].do{|p|{_: :img, src: p[0].uri, style: "#{rand(2).zero? ? 'left' : 'right'}: 0"}},
                {_: :span, c: r[Creator].do{|c|
                    c[0].respond_to?(:uri) ? c[0].uri.abbrURI : c[0].to_s}}]}},' ',
        {_: :span, :class => :tw, c: r[Content]},"<br>\n"]}]}

  F['view/'+SIOCt+'InstantMessage']=F['view/chat']
  F['view/'+SIOCt+'MicroblogPost']=F['view/chat']

end
