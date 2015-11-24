#watch __FILE__
class R

  ViewGroup[SIOC+'InstantMessage'] = ViewGroup[SIOC+'MicroblogPost'] = -> d,e {
    d.map{|u,r| ViewA[SIOC+'InstantMessage'][r,e]}}

  ViewA[SIOC+'InstantMessage'] = ViewA[SIOC+'MicroblogPost'] = -> r,e {
    name = r[Label].justArray[0] || ''
    label = name.gsub(/[^a-zA-Z0-9]/,'')
    e[:label][label] = true
    {href: r.uri,
     id: r.uri,
     class: :ublog,
     c: [
       {_: :span, class: 'body', c: r[Content]},' ',
       {_: :span, class: 'date', c: r[Date][0].split('T')[1][0..4]},' ',
       {_: :span, class: :creator, c: {_: :a, href: r.uri, name: label, c: name}},' ',
     ]}}

  ViewA[SIOC+'ChatLog'] = -> log,e {
    graph = {}
    log[LDP+'contains'].map{|line| graph[line.uri] = line}
    [{class: :chatLog, name: log[Label], href: log.uri, id: log.uri,
     c: [{_: :b, c: log[Label]},
         ViewGroup[SIOC+'InstantMessage'][graph,e]]},'<br>']}

  # drop messages in channel-hour bins of type ChatLog
  Abstract[SIOC+'InstantMessage'] = Abstract[SIOC+'MicroblogPost'] = -> graph, msgs, e {
    msgs.map{|msgid,msg|
      creator = msg[Creator].justArray[0]
      chan = msg[SIOC+'channel'].justArray[0] || ''
      date = msg[Date].justArray[0]
      label = "#{date[11..12]}00"
      uri = '/news/' + date[0..12].gsub(/\D/,'/') + '#' + label
      graph[uri] ||= {'uri' => uri}
      graph[uri][SIOC+'addressed_to'] ||= chan
      graph[uri][Date] ||= date[0..12]+':30:00'
      graph[uri][Label] ||= label
      graph[uri][Type] ||= R[SIOC+'ChatLog']
      graph[uri][LDP+'contains'] ||= []
      graph[uri][LDP+'contains'].push msg
      graph.delete msgid
    } unless e[:nosummary]}

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
        yield s, Label,             m[2]
        yield s, Content,             m[3].hrefs(true)
        yield s, Type,                R[SIOC+'InstantMessage']
      } rescue nil
    }
  end

  def triplrTwitter
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

  def twGET g; triplrCache :triplrTwitter, g, nil, IndexFeedJSON end

end
