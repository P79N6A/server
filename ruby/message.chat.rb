watch __FILE__
class R

  # cluster by channel*hour
  Abstract[SIOC+'InstantMessage'] = -> graph, g, e {
   puts g.keys
  }

  # IRC

  def triplrIRC &f
    i=-1 # line index

    day = dirname.split('/')[-3..-1].do{|dp|
      dp.join('-') if dp[0].match(/^\d{4}$/)
    }||''
    doc = uri.gsub '#','%23'
    channel = bare

    r.lines.map{|l|
      l.scan(/(\d\d):(\d\d) <[\s@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = doc + '#' + (i+=1).to_s
        yield s, Date,                day+'T'+m[0]+':'+m[1]+':00'
        yield s, SIOC+'channel', channel
        yield s, Creator,             m[2]
        yield s, Content,             m[3].hrefs(true)
        yield s, Type,                R[SIOC+'InstantMessage']
      } rescue nil
    }
  end

  # twitter

  def triplrTwUsers
    open(pathPOSIX).readlines.map{|l|
      yield 'https://twitter.com/'+l.chomp, Type, R[Resource]}
  end

  def triplrTwMsg
    base = 'https://twitter.com'
    nokogiri.css('div.tweet > div.content').map{|t|
      s = base + t.css('.js-permalink').attr('href') # subject URI
      yield s, Type, R[SIOC+'MicroblogPost']
      yield s, Creator, R(base+'/'+t.css('.username b')[0].inner_text)
      yield s, Label, t.css('.fullname')[0].inner_text
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a| # bind hostname to paths
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end

  def tw g
    node.readlines.shuffle.each_slice(22){|s|
      u = 'https://twitter.com/search?f=realtime&q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
      u.R.twGET g}
  end

  def twGET g; triplrStoreJSON :triplrTwMsg, g, nil, FeedArchiverJSON end

end
