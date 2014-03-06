#watch __FILE__
class R

  def triplrIRC &f
    i=-1
    day = dirname.uri.split('/')[-3..-1].do{|dp|
      dp.join('-') if dp[0].match(/^\d{4}$/)
    }||''
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
        yield s, Type,                R[SIOCt+'InstantMessage']
        yield s, Type,                R[SIOC+'Post']
        yield s, SIOC+'link',        (m[3].match(/http:\//) ? 'true' : 'false')
      } rescue nil
    }
  end

  def tw g
    node.readlines.shuffle.each_slice(22){|s|
      R['https://twitter.com/search/realtime?q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].addDocs :triplrTweets, g, nil, FeedArchiverJSON}
  end

  FeedArchiverJSON = -> doc, graph, host {
    doc.roonga host
    graph.map{|u,r|
      r[Date].do{|t| # link doc to date-index
        t = t[0].gsub(/[-T]/,'/').sub /(.00.00|Z)$/, '' # trim normalized timezones and non-unique symbols
        b = (u.sub(/http:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
        doc.ln R["http://#{host}/news/#{t}#{b}e"]}}
  doc}

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
    F['baseview/chat'][d, e, ->{d.map{|u,r|F['itemview/chat'][r,e]}}]}

  fn 'itemview/chat',->r,e{
    r[Type] && [*r[Type]].map(&:maybeURI).include?(SIOCt+'MailMessage') && r[:mail]=true
    r[Content] && r[Date] && r[Date][0] &&
    [r[Date][0].match(/T([0-9:]{5})/).do{|m|m[1]},
     {_: :span, :class => :nick, c: {_: :a, href: r[Atom+'/link/alternate'].do{|a|a[0].uri}||r.url,
            c: [r[Atom+"/link/image"].do{|p| {_: :img, src: p[0].uri, style: "#{rand(2).zero? ? 'left' : 'right'}: 0"}},
                {_: :span, c: r[Name]||r[Creator]||'#'}]}},' ',
        {_: :span, :class => :tw, # skip redundant title fields
       c: [((r[Title].to_s == r[Content].to_s || r.uri.match(/twitter/)) && '' ||
            {_: :a, :class => :title, href: r.url, c: r[Title]}), # skip quoted mail-lines & abbreviate
           r[:mail] ? (r[Content].map{|c|c.lines.to_a.grep(/^[^&@_]+$/)[0..21]}) : r[Content],
          ]},"<br>\n"]}

  F['view/'+SIOCt+'BoardPost']=->d,e{
    d.map{|u,r|
      {class: :BoardPost, style: "background-color:#ff4500;color:#fff;float:left;border-radius:.8em;padding:.4em;max-width:42em;margin:.5em",
        c: F['itemview/chat'][r,e]}}}

  fn 'baseview/chat',->d,e,c{
    [(H.once e,'chat.head',(H.css '/css/tw'),{_: :style, c: "body {background-color: #{R.c}}\n"}),c.()]}

  F['view/'+SIOCt+'InstantMessage']=F['view/chat']
  F['view/'+SIOCt+'MicroblogPost']=F['view/chat']

end
