# coding: utf-8
class R

  def triplrIRC &f
    i=-1
    day = dirname.split('/')[-3..-1].do{|dp|
      dp.join('-') if dp[0].match(/^\d{4}$/)
    }||''
    doc = uri.gsub '#','%23'
    channel = bare
    r.lines.map{|l|
      l.scan(/(\d\d):(\d\d) <[\s@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = doc + '#' + (i+=1).to_s
        yield s, Date,                day+'T'+m[0]+':'+m[1]+':00'
        yield s, SIOC+'ChatChannel', channel
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

  ViewGroup[SIOC+'InstantMessage'] = ViewGroup[SIOC+'MicroblogPost'] = -> d,e {
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
     {_: :style,
      c: label.map{|n,l|
        "table.chat td.creator.l#{l[:id]} {background-color: #{randomColor}}" if l[:c] > 1}.cr },
     H.css('/css/chat',true)]}

  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = -> d,e {
    colors = {}
    titles = {}
    q = e.q
    quotes = if q['quotes'] == "yes"
               true
             elsif q['quotes'] == "no"
               false
             elsif d.keys.size < 6
               true
             else
               false
             end

    # show/hide quoted material
    d.map{|u,r| r[Content] = r[Content].justArray.map{|c|
      c.lines.map{|l|l.match(/^<div class='q'/) ? "" : l}.join}} unless quotes

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
             sourceName: d,
             sourceColor: '#eee',
             targetColor: '#eee',
             sourcePos: (max - m) / range,
             targetPos: (max - yesterday[1]) / range,
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
            pos = (max - mt[0].to_f) / range
            arc[:sourcePos] = pos}
          t[Mtime].do{|mt|
            pos = (max - mt[0].to_f) / range
            arc[:targetPos] = pos}
          arcs.push arc }}}

    # View
    [H.css('/css/mail',true),
     {_: :style,
      c: colors.map{|name,c|
        ".mail .header a[name=\"#{name}\"], .mail[author=\"#{name}\"] .body a {color: #000; background-color: #{c}}\n"}},
#     {_: :a, class: :noquote, rel: :nofollow, href: CGI.escapeHTML(q.merge({'quotes' => quotes ? 'no' : 'yes'}).qs), c: quotes ? '&lt;' : '&gt;', title: "#{quotes ? "hide" : "show"} quotes"},
     {class: :messages, c: d.resources(e).reverse.map{|r| # a message
        author = r[Creator].justArray[0].do{|c| c.R.fragment } || 'anonymous'
        {class: :mail, author: author, id: r.uri,
         c: [{class: :header,
              c: [r[Title].justArray[0].do{|t|
                    title = t.sub ReExpr, ''
                    if titles[title] # already shown
                      nil
                    else
                      titles[title] = true
                      [{_: :a, class: :subject, href: r[SIOC+'has_discussion'].justArray[0].do{|d|d.uri}||r.uri, c: title},"<br/>"]
                    end},
                  r[Creator].justArray[0].do{|c| {_: :a, class: :author, name: author, href: c.uri, c: author}},
                  r[To].justArray.map{|o|
                    {_: :a, class: :to, href: o.R.dirname, c: o.R.fragment} unless colors[o.R.fragment]}.intersperse(' '), ' ',
                  r[SIOC+'has_parent'].do{|ps|
                    ps.justArray.map{|p| # replied-to messages
                      d[p.uri].do{|r| # target msg
                        c = r[Creator][0].R.fragment
                        {_: :a, name: c, href: '#'+p.uri, c: c}}}.intersperse(' ')}, ' ',
                  r[SIOC+'reply_to'].do{|c|
                    {_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'}},
                  r[Date].do{|d| {_: :a, class: :ts, href: r.uri, c: d[0].sub('T',' ')}},
                  r[SIOC+'has_discussion'].justArray[0].do{|d|
                    {_: :a, class: :discussion, href: d.uri + '#' + (r.uri||''), c: '≡', title: 'goto thread'} unless e[:thread]}]},
             r[Content].do{|c|{class: :body, c: c}},
             r[WikiText].do{|c|
               {class: :body, c: Render[WikiText][c]}},
             [DC+'hasFormat', SIOC+'attachment'].map{|p|
               r[p].justArray.map{|o|
                 {_: :a, class: :attached, href: o.uri, c: '⬚ ' + o.R.basename}}}]}}},
     H.js('/js/d3.v3.min'), {_: :script, c: "var links = #{arcs.to_json};"},
     H.js('/js/timegraph',true)]}

end
