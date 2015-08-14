# coding: utf-8
#watch __FILE__
class R

  ViewA[SIOC+'InstantMessage'] = ViewA[SIOC+'MicroblogPost'] = -> r,e {
    [{_: :span, class: 'date', c: r[Date][0].split('T')[1][0..4]},
     r[Creator].do{|c|
       name = c[0].respond_to?(:uri) ? c[0].uri.split(/[\/#]/)[-1] : c[0].to_s
       e[:label][name] ||= {c: 0, id: (e[:count] += 1).to_s}
       e[:label][name][:c] += 1
       {class: 'creator l' + e[:label][name][:id], c: {_: :a, href: r.uri, c: name }}},
     {_: :span, class: 'body', c: r[Content]},
     '<br>'
    ]}

  ViewGroup[SIOC+'InstantMessage'] = ViewGroup[SIOC+'MicroblogPost'] = -> d,e {
    e[:label] ||= {}
    e[:count] = 0
    e.q['a'] = 'sioc:channel'
    [{class: :chat, c: d.map{|u,r|ViewA[SIOC+'InstantMessage'][r,e]}},
     {_: :style,
      c: e[:label].map{|n,l|
        ".chat .creator.l#{l[:id]} {background-color: #{randomColor}}\n.chat .creator.l#{l[:id]} a {color:#fff}" if l[:c] > 1}.cr },
    ]}

  ViewA[SIOC+'ChatLog'] = -> log,e,d {

    # lines to graph
    graph = {}
    log[LDP+'contains'].map{|line|
      graph[line.uri] = line}

    {class: :chatLog,
     selectable: true,
     id: URI.escape(log.R.fragment),
     c: [{_: :b,
          c: "#{log['#hour']}00 #{log[SIOC+'channel']}"},
         ViewGroup[SIOC+'InstantMessage'][graph,e]]}}

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,e,d {
    name = nil
    href = r.uri
    author = r[Creator].justArray[0].do{|c|
      authorURI = c.class==Hash || c.class==R
      name = if authorURI
               u = c.R
               u.fragment || u.basename || u.host || 'anonymous'
             else
               c.to_s
             end
      [{_: :a, name: name, c: name, href: authorURI ? c.uri : '#'},' ']}

    discussion = r[SIOC+'has_discussion'].justArray[0].do{|d|
      if e[:thread]
        href = r.uri + '#' + (r.R.path||'') # link to standalone msg
        nil
      else
        href = d.uri + '#' + (r.R.path||'') # link to msg in thread
        {_: :a, class: :discussion, href: href, c: '≡', title: 'show in thread'}
      end}

    {class: :mail, name: name, id: r.R.path, href: href, selectable: :true,
     c: [r[Title].justArray[0].do{|t|
           {_: :a, class: :title,
            href: r.uri,
            c: CGI.escapeHTML(t)}},"<br>\n",
         {class: :header,
          c: [r[To].justArray.map{|o|
                o = o.R
                [{_: :a, class: :to, href: o.uri, c: o.fragment || o.path || o.host},' ']},
              ' &larr; ',
              author,
              r[Date].do{|d| [{_: :a, class: :date, href: r.uri, c: d[0].sub('T',' ')},' ']},
              r[SIOC+'reply_to'].do{|c|
                [{_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'},' ']},
              discussion
             ].intersperse("\n  ")},

         r[Content].justArray.map{|c| {class: :body, c: c}},
         r[WikiText].do{|c|{class: :body, c: Render[WikiText][c]}},
         [DC+'hasFormat', SIOC+'attachment'].map{|p|
           r[p].justArray.map{|o|
             {_: :a, class: :attached, href: o.uri, c: '⬚ ' + o.R.basename}}}]}}

    ViewGroup[SIOC+'ChatLog'] = ViewGroup[SIOC+'BlogPost'] =  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = -> d,e {
    colors = {}
    q = e.q
    arcs = []
    days = {}

    # normalize mtimes to float
    mtimes = d.values.map{|s|
      s[Date].justArray[0].do{|d|
        day = d[0..9]
        days[day] ||= day.to_time.to_f} # unique days
      s[Mtime]
    }.flatten.compact.map(&:to_f)

    # find max/min mtimes
    min = mtimes.min || 0
    max = mtimes.max || 1
    range = (max - min).min(0.1)
    days = days.sort_by{|_,m|m}
    yesterday = days[0]

    # contruct temporal-arcs
    days.map{|d,m|
      arc = {source: '/'+d.gsub('-','/'),
             target: '/'+yesterday[0].gsub('-','/'),
             sourceName: d,
             sourceColor: '#fff',
             targetColor: '#fff',
             sourcePos: (m - min) / range,
             targetPos: (yesterday[1] - min) / range,
            }
      yesterday = [d,m]
      arcs.push arc}

    # construct reference-arcs
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

    # HTML
    [H.css('/css/mail',true),H.css('/css/chat',true),
     {_: :style,
      c: [colors.map{|name,c|
            "[name=\"#{name}\"] {color: #000; background-color: #{c}}\n"},
          (1..15).map{|depth|
            back = rand(2) == 0
            ".mail .q[depth=\"#{depth}\"] {#{back ? 'background-' : ''}color: #{R.randomColor}; #{back ? '' : 'background-'}color:#000}\n"}
         ]},
     {class: :messages, id: :messages,
      c: [e[:Links][:prev].do{|n|
            {_: :a, id: :first, rel: :prev, c: '&larr;', href: CGI.escapeHTML(n.to_s)}},
          d.resources(e).reverse.map{|r|
            ViewA[r[Type].justArray[0].uri][r,e,d]},
          e[:Links][:next].do{|n|
            uri = CGI.escapeHTML(n.to_s)
            {_: :a, id: n, rel: :next, c: '&rarr;', href: uri, next: uri + '#first'}}
         ]},'<br clear=all>',
     {style: "height: 86px;width: 100%;position:fixed;bottom:0;left:0;z-index:1;background-color:white;opacity: 0.2"},
     H.js('/js/d3.min'), {_: :script, c: "var arcs = #{arcs.to_json};"},
     H.js('/js/timegraph')
    ]}

end
