#watch __FILE__
class R

  def triplrIRC &f
    i=-1
    day = dirname.split('/')[-3..-1].do{|dp|
      dp.join('-') if dp[0].match(/^\d{4}$/)
    }||''
    doc = uri.gsub '#','%23'
    channel = bare
    r.lines.map{|l|
=begin
19:10 [    kludge] _abc_: because people discovered that APL was totally unmaintainable.  People wrote code and then went to lunch and when they came back they couldn't figure out what the hell they had done.
19:10 [     _abc_] Sounds like Perl
=end
      l.scan(/(\d\d):(\d\d) \[[\s@]*([^\(\]]+)[^\]]*\] (.*)/){|m|
        s = doc + '#' + doc + ':' + (i+=1).to_s
        yield s, Date,                day+'T'+m[0]+':'+m[1]+':00'
        yield s, SIOCt+'ChatChannel', channel
        yield s, Creator,             m[2]
        yield s, Content,             m[3].hrefs(true)
        yield s, Type,                R[SIOCt+'InstantMessage']
      } rescue nil
    }
  end

  def tw g
    node.readlines.shuffle.each_slice(22){|s|
      u = 'https://twitter.com/search/realtime?q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
      u.R.twGET g}
  end

  def twGET g
    triplrCacheJSON :triplrTwMsg, g, nil, FeedArchiverJSON
  end

  def triplrTwUsers
    open(pathPOSIX).readlines.map{|l|
      yield 'https://twitter.com/'+l.chomp, Type, R[Resource]}
  end

  def triplrTwMsg
    base = 'https://twitter.com'
    nokogiri.css('div.tweet').map{|t|
      s = base + t.css('.js-permalink').attr('href') # subject URI
      yield s, Type, R[SIOCt+'MicroblogPost']
      yield s, Creator, R(base+'/'+t.css('.username b')[0].inner_text)
      yield s, Name, t.css('.fullname')[0].inner_text
      yield s, Atom+"/link/image", R(t.css('.avatar')[0].attr('src'))
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a| # bind hostname to paths
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end

  ViewA[SIOC+'Forum'] = -> r,e {
    {_: :a, href: r.R.stripFrag.uri + '?view=edit&type=sioct:BoardPost', c: 'new post'}
  }

  ViewA[SIOCt+'InstantMessage'] = ViewA[SIOCt+'MicroblogPost'] = -> r,e {
    [{_: :span, class: :date, c: r[Date][0].split('T')[1][0..4]}, " ",
     r[Creator].do{|c|
       name = c[0].respond_to?(:uri) ? (c[0].R.fragment || c[0].R.basename) : c[0].to_s
       e[:creators][name] = R.cs
       {_: :a, href: r.uri, creator: name, c: name }}," ", r[Content],"<br>\n"]}

  ViewGroup[SIOCt+'InstantMessage'] = -> d,e {
    e.q['a'] = 'sioct:ChatChannel,sioc:has_creator'
    e[:creators] ||= {}
    [Facets[d,e],
     H.css('/css/chat',true),
     {_: :style, c: e[:creators].map{|n,c|"a[creator='#{n}'] {color:#fff;background-color: #{c}}"}.cr}]}

  ViewGroup[SIOCt+'MicroblogPost'] = -> d,e {
    label = {}
    count = 0
    [{_: :table, class: :chat, c: d.resources(e).reverse.map{|r|
        {_: :tr,
         c: [{_: :td, class: :date, c: r[Date][0].split('T')[1][0..4]},
             r[Creator].do{|c|
               name = c[0].respond_to?(:uri) ? c[0].uri.split(/[\/#]/)[-1] : c[0].to_s
               label[name] ||= {c: 0, id: (count += 1).to_s}
               label[name][:c] += 1
               {_: :td, class: 'creator l'+label[name][:id], c: {_: :a, href: r.uri, c: name }}} || {_: :td},
             {_: :td, class: :body, c: r[Content]}]}}.cr },
     {_: :style, c: label.map{|n,l| "table.chat td.creator.l#{l[:id]} {background-color: #{cs}}" if l[:c] > 1}.cr },
     H.css('/css/chat',true)]}
  
end
