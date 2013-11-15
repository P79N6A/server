#watch __FILE__
class E

  # sprintf() formats in <https://github.com/infodaemon/www/blob/60a9b5f51cf15d5723afd9172767843d97190d8f/css/i/lotek.theme>
  def triplrIRC &f
    i=-1
    day = dirname.uri.split('/')[-3..-1].join('-')
    doc = uri.sub '#','%23'
    channel = bare
    yield doc,Date,day
    r.lines.map{|l|
      l.scan(/(\d\d):(\d\d) \[[\s@]*([^\(\]]+)[^\]]*\] (.*)/){|m|
        s = doc + '#' + doc + ':' + (i+=1).to_s
        yield s, Date,                day+'T'+m[0]+':'+m[1]+':00'
        yield s, SIOCt+'ChatChannel', channel
        yield s, Creator,             m[2]
        yield s, Content,             m[3].hrefs(true)
        yield s, Type,                E[SIOC+'Post']
        yield s, Type,                E[SIOCt+'InstantMessage']
        yield s, 'hasLink',           (m[3].match(/http:\//) ? 'true' : 'false')
        yield s, 'hasNum', 'true' if m[3].match(/\d/)} rescue (puts "skipped #{l}")
    }
  end

  def tw g='m'
    no.readlines.shuffle.each_slice(22){|s|
      E['https://twitter.com/search/realtime?q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].addJSON :triplrTweets, g}
  end

  def triplrTweets
    base = 'http://twitter.com'
    nokogiri.css('div.tweet').map{|t|
      s = base + t.css('a.details').attr('href') # subject URI
      yield s, Type, E[SIOCt+'MicroblogPost']
      yield s, Creator, E(base+'/'+t.css('.username b')[0].inner_text)
      yield s, SIOC+'name',t.css('.fullname')[0].inner_text
      yield s, Atom+"/link/image", E(t.css('.avatar')[0].attr('src'))
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a|
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, content.inner_html
    }
  end

  fn 'head/chat',->d,e{
     t = d.map{|_,r|r[Date]}.flatten.compact.map &:to_time
     c = d.map{|_,r|r[Content]}.compact.size
    [{_: :title, c: "#{c} post#{c!=1 && 's'} #{t.min} -> #{t.max}"},
     (Fn 'head.formats',e)]}

  fn 'view/chat',->d,e{
    Fn'view/chat/base',d,e,->{d.map{|u,r|Fn 'view/chat/item',r,e}}}

  fn 'view/chat/item',->r,e{
    line = r.E.frag
    r[Type] && r[Type].map(&:uri).include?(SIOCt+'MailMessage') && r[:mail]=true
    r[Content] && 
    [{_: :a, id: line},
     {_: :a, :class => :date, href: r.url, c: r[Date][0].match(/T([0-9:]{5})/)[1]},
     {_: :span, :class => :nick, c: {_: :a, href: r[Atom+'/link/alternate'].do{|a|a[0].uri}||r.url,
            c: [r[Atom+"/link/image"].do{|p| {_: :img, class: :a, src: p[0].uri}},
                {_: :span, c: r[SIOC+'name']||r[Creator]||'#'}]}},' ',
        {_: :span, :class => :tw, 
       c: [r[Atom+'/link/media'].do{|a|
             a.compact.map{|a|{_: :a, href: r.url, c: {_: :img, src: a.uri}}}},
           ((r[Title].to_s==r[Content].to_s || r.uri.match(/twitter/)) && '' ||
            {_: :a, href: r.url, c: r[Title],:class => r[:mail] ? :titleMail : :title}),
           r[:mail] ? (r[Content].map{|c|c.lines.to_a.grep(/^[^&@_]+$/)[0..21]}) : r[Content],
          ]},' ',
     {_: :a, class: :line, href: '#'+line, c: '&nbsp;'},
     "<br>\n"] if r.uri}
  
  fn 'view/chat/base',->d,e,c{
    [(H.once e,'chat.head',(H.css '/css/tw'),{_: :style, c: "body, span.nick span, a {background-color: #{E.c}}\n"}),
     {:class => :ch, c: c.()},
     (H.once e,'chat.tail',{id: :b})]}

  F['view/'+SIOCt+'InstantMessage']=F['view/chat']
  F['view/'+SIOCt+'MicroblogPost']=F['view/chat']

end
