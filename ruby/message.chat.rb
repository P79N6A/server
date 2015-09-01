#watch __FILE__
class R

  # group by channel-hour
  Abstract[SIOC+'InstantMessage'] = Abstract[SIOC+'MicroblogPost'] = -> graph, msgs, e {
    msgs.map{|uri,msg|
      creator = msg[Creator].justArray[0]
      name = creator.respond_to?(:uri) ? creator.uri.split(/[\/#]/)[-1] : creator.to_s
      msg[Label] = name
      chan = msg[SIOC+'channel'].justArray[0] || ''
      date = msg[Date].justArray[0]
      hour = date[11..12]
      log = '#' + chan + '.' + hour
      graph[log] ||= {
        'uri' => log,
        Type => R[SIOC+'ChatLog'],
        SIOC+'channel' => chan,
        '#hour' => hour,
        LDP+'contains' => [],
        SIOC+'addressed_to' => chan,
      }
      graph[log][LDP+'contains'].push msg
      graph[log][Date] = date[0..12]+':59:59' if !graph[log][Date]
      graph.delete uri
    } unless e[:nosummary]
  }

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
      yield s, SIOC+'channel', 'twitter'
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
