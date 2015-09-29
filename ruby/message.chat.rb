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
#     selectable: true,
     c: [
       {_: :span, class: 'body', c: r[Content]},' ',
       {_: :span, class: 'date', c: r[Date][0].split('T')[1][0..4]},' ',
       {_: :span, class: :creator, c: {_: :a, href: r.uri, name: label, c: name}},' ',
     ]}}

  ViewA[SIOC+'ChatLog'] = -> log,e {
    graph = {}
    date = log[Date].justArray[0]
    time = date.to_time
    hour = date[0..12] + ':00:00'
    hourTime = hour.to_time
    e[:timelabel][hour] = true
    lineCount = 0
    log[LDP+'contains'].map{|line|
      e[:arcs].push({source: line.uri,
                     sourceTime: line[Date].justArray[0].to_time,
                     sourceLabel: line[Label],
                     target: log.uri,
                     targetTime: hourTime}) if lineCount < 17
      lineCount += 1
      graph[line.uri] = line}

    [{class: :chatLog, name: log[Label], selectable: true, date: date, href: log.uri, id: log.uri,
     c: [{_: :b, c: log[Label]},
         ViewGroup[SIOC+'InstantMessage'][graph,e],
        ]},'<br>']}

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

  ViewGroup[SIOC+'ChatLog'] = ViewGroup[SIOC+'BlogPost'] =  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = -> d,e {
    e[:arcs] = []
    e[:timelabel] = {}
    prior = {'uri' => '#'}
    d.values.map{|s|
      if s[SIOC+'has_parent'] # explicit parent
        s[SIOC+'has_parent'].justArray.map{|o|
          d[o.uri].do{|t| # arc target
            sLabel = s[Creator].justArray[0].do{|c|c.R.fragment}
            tLabel = t[Creator].justArray[0].do{|c|c.R.fragment}
            e[:label][sLabel] = true
            e[:label][tLabel] = true
            arc = {source: s.uri, target: o.uri, sourceLabel: sLabel, targetLabel: tLabel}
            s[Mtime].do{|mt| arc[:sourceTime] = mt[0]}
            t[Mtime].do{|mt| arc[:targetTime] = mt[0]}
            e[:arcs].push arc }}
      end
    }

    # labels
    (1..15).map{|depth| e[:label]["quote"+depth.to_s] = true}

    # facet-filter properties
    defaultFilter = e[:thread] ? Creator : 'sioc:addressed_to'
    e.q['a'] ||= defaultFilter
    e.q['reverse'] ||= true
    timegraph = false

    # HTML
    [H.css('/css/message',true),
     {class: :msgs,
      c: [(d.values[0][Title].justArray[0].do{|t|
             title = t.sub ReExpr, ''
             {_: :h1, c: CGI.escapeHTML(title)}} if e[:thread]),
          Facets[d,e]]}, # filterable resources
     (#  max/min time-values
      times = e[:arcs].map{|a|[a[:sourceTime],a[:targetTime]]}.
              flatten.compact.map(&:to_f)
      min = times.min || 0
      max = times.max || 1
      range = (max - min).min(0.1)

      # scale times to range
      e[:arcs].map{|a|
        a[:sourcePos] = (a[:sourceTime].to_f - min) / range
        a[:targetPos] = (a[:targetTime].to_f - min) / range
        a.delete :sourceTime
        a.delete :targetTime }
      timegraph = e[:arcs].size > 1

      e[:sidebar].push({id: :timegraph,
                        c: {_: :svg,
                            c: e[:timelabel].map{|l,_|
                              pos = (max - l.to_time.to_f) / range * 100
                              y = pos.to_s + '%'
                              [{_: :line, stroke: '#333', 'stroke-dasharray' => '2,2', x1: 0, x2: '100%', y1: y, y2: y},
                               {_: :text, 'font-size'  =>'.8em',c: l.sub('T',' '), dy: -3, x: 0, y: y}
                              ]}}}) if timegraph

      nil),
     ([{_: :script, c: "var arcs = #{e[:arcs].to_json};"},
       H.js('/js/d3.min'), H.js('/js/timegraph',true)] if timegraph)]}

  # mint identifiers for various POSTed resource-types - forum usecase
  Identify[SIOC+'Thread'] = -> thread, forum, env {
    forum.uri + Time.now.iso8601[0..10].gsub(/[-T]/,'/') + thread[Title].slugify + '/'
  }

  Identify[SIOC+'BoardPost'] = -> post, thread, env {
    uri = thread.uri + Time.now.iso8601.gsub(/[-+:T]/, '')
    post[SIOC+'reply_to'] = R[thread.uri + '?new&reply_of=' + CGI.escape(uri)]
    uri
  }

  Create[SIOC+'Thread'] = -> thread, forum, env {
    thread[SIOC+'has_container'] = R[forum.uri]
  }

  Create[SIOC+'BoardPost'] = -> post, thread, env {
    env.q['reply_of'].do{|re|
      post[SIOC+'has_parent'] = re.R
    }
    post[SIOC+'has_discussion'] = R[thread.uri]
    post[Title] = thread[Title]
  }

end
