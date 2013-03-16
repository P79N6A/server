#watch __FILE__
class E

  def log &f
    i=-1
    day = dirname.uri.split('/')[-3..-1].join('-')
    doc = uri.sub '#','%23'
    chan = bare
    yield doc,'chan',chan
    r.scan(/(\d\d):(\d\d) \[[\s@]*([^\(\]]+)[^\]]*\] (.*)/){|m|
      s = doc + '#' + doc + ':' + (i+=1).to_s
      yield s,Date,day+'T'+m[0]+':'+m[1]+':00'
      yield s,'chan',chan
      yield s,Creator,m[2]
      yield s,Content,m[3].hrefs(true)
      yield s,Type,E[SIOCt+'InstantMessage']
      yield s,'hasLink',(m[3].match(/http:\//) ? 'true' : 'false')
      yield s,'hasNum','true' if m[3].match(/\d/)
    } rescue nil
    yield doc,Date,day
    lines &f
  end

  def tw g
    no.readlines.shuffle.each_slice(24){|s|puts E['http://search.twitter.com/search.atom?q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].getFeed g}
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
            c: [{_: :img, class: :a, src: r[Atom+"/link/image"][0].uri},
                {_: :span, c: r[Creator][0].do{|c|c.respond_to?(:uri) ? c.uri.split(/@/)[0] : c.match(/[^\(]+/)}||'#'}]}},' ',
        {_: :span, :class => :tw, style: 'background-color:#'+(rand 48).do{|l|'%02x%02x%02x' % [l,l,l]}, 
       c: [r[Atom+'/link/media'].do{|a|a.map{|a|{_: :a, href: r.url, c: {_: :img, src: a.uri}}}},
           ((r[Title].to_s==r[Content].to_s || r.uri.match(/twitter/)) && '' ||
            {_: :a, href: r.url, c: r[Title],:class => r[:mail] ? :titleMail : :title}),
           r[:mail] ? (r[Content].map{|c|c.lines.to_a.grep(/^[^&@_]+$/)[0..21]}) : r[Content],
          ]},' ',
     {_: :a, class: :line, href: '#'+line, c: '&nbsp;'},
     "<br>\n"] if r.uri}
  
  fn 'view/chat/base',->d,e,c{
    [(H.once e,'chat.head',(H.css '/css/tw'),{_: :style, c: "span.nick span, a {background-color: #{E.c}}\n"}),
     {:class => :ch, c: c.()},
     (H.once e,'chat.tail',{id: :b})]}

  F['view/'+SIOCt+'InstantMessage']=F['view/chat']

end
