# coding: utf-8
#watch __FILE__
class R

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

  ViewA[SIOC+'InstantMessage'] = ViewA[SIOC+'MicroblogPost'] = -> r,e {
    [{_: :span, class: 'date', c: r[Date][0].split('T')[1][0..4]},
     r[Creator].do{|c|
       name = c[0].respond_to?(:uri) ? c[0].uri.split(/[\/#]/)[-1] : c[0].to_s
       e[:label][name] ||= {c: 0, id: (e[:count] += 1).to_s}
       e[:label][name][:c] += 1
       {class: 'creator l' + e[:label][name][:id], c: {_: :a, href: r.uri, c: name }}},
     {_: :span, class: 'body', c: r[Content]}]}

  ViewGroup[SIOC+'InstantMessage'] = ViewGroup[SIOC+'MicroblogPost'] = -> d,e {
    e[:label] ||= {}
    e[:count] = 0
    e.q['a'] = 'sioc:channel'
    [{class: :chat, c: Facets[d,e]},
     {_: :style,
      c: e[:label].map{|n,l|
        ".chat .creator.l#{l[:id]} {background-color: #{randomColor}}" if l[:c] > 1}.cr },
     H.css('/css/chat',true)]}

  ViewGroup[SIOC+'BlogPost'] =  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = -> d,e {
    colors = {}
    q = e.q
    arcs = []
    days = {}
    mtimes = d.values.map{|s|
      s[Date].justArray[0].do{|d|
        day = d[0..9]
        days[day] ||= day.to_time.to_f}
      s[Mtime]
    }.flatten.compact.map(&:to_f)
    min = mtimes.min || 0
    max = mtimes.max || 1
    range = (max - min).min(0.1)
    days = days.sort_by{|_,m|m}
    yesterday = days[0]

    # temporal arcs
    days.map{|d,m|
      arc = {source: '/'+d.gsub('-','/'),
             target: '/'+yesterday[0].gsub('-','/'),
             sourceName: d.gsub('-','..'),
             sourceColor: '#fff',
             targetColor: '#fff',
             sourcePos: (m - min) / range,
             targetPos: (yesterday[1] - min) / range,
            }
      yesterday = [d,m]
      arcs.push arc}

    # reference arcs
    d.values.map{|s| # source
      s[SIOC+'has_parent'].justArray.map{|o| # msg source -> target arcs
        d[o.uri].do{|t| # target
          arc = {source: s.uri, target: o.uri}
          author = s[Creator].justArray[0].do{|c|c.R.fragment}
          arc[:sourceColor] = colors[author] ||= randomColor
          author = t[Creator].justArray[0].do{|c|c.R.fragment}
          arc[:targetColor] = colors[author] ||= randomColor
          s[Mtime].do{|mt|
            pos = (mt[0].to_f - min) / range
            arc[:sourcePos] = pos}
          t[Mtime].do{|mt|
            pos = (mt[0].to_f - min) / range
            arc[:targetPos] = pos}
          arcs.push arc }}}

    timegraph = arcs.size > 1

    # HTML
    [H.css('/css/mail',true),
     {_: :style,
      c: colors.map{|name,c|
        ".mail a[name=\"#{name}\"], .mail[author=\"#{name}\"] .body a {color: #000; background-color: #{c}}\n"}},

     {class: :messages, id: :messages,
      c: d.resources(e).map{|r|
        {class: :mail, id: r.uri,
         c: [
           r[Title].justArray[0].do{|t|
             {_: :a, class: :title,
              href: r.uri,
              c: ' '+t}},'<br>',
           r[To].justArray.map{|o|
             [{_: :a, class: :to, href: o.R.dirname+'?set=page', c: o.R.fragment}, ' ']},
           r[SIOC+'has_parent'].do{|ps|
             ps.justArray.map{|p| # replied-to messages
               d[p.uri].do{|r| # target msg in graph
                 r[Creator].justArray[0].do{|c|
                   c = c.R.fragment
                   [{_: :a, name: c, href: '#'+p.uri, c: c}, ' ']
                 }}}},'&larr; ',
           r[Creator].justArray[0].do{|c|
             author = c.R.fragment || 'anonymous'
             {_: :a,
               name: author,
               href: c.R.dirname+'?set=page',
               c: author}},' ',
           r[Date].do{|d| {_: :a, class: :date, href: r.uri, c: d[0].sub('T',' ')}},' ',
           r[SIOC+'reply_to'].do{|c|
             {_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'}},' ',
           r[SIOC+'has_discussion'].justArray[0].do{|d|
             {_: :a, class: :discussion,
              href: d.uri + '#' + (r.R.path||''),
              c: '≡', title: 'show in thread'} unless e[:thread]},
           r[Content].do{|c| {class: :body, c: c}},
           r[WikiText].do{|c|{class: :body, c: Render[WikiText][c]}},
           [DC+'hasFormat', SIOC+'attachment'].map{|p|
             r[p].justArray.map{|o|
               {_: :a, class: :attached, href: o.uri, c: '⬚ ' + o.R.basename}}}
         ]}}},
      (if timegraph
       [H.js('/js/d3.min'),
        {_: :script, c: "var arcs = #{arcs.to_json};"},
        H.js('/js/timegraph',true)]
       end)
    ]}
  
end
