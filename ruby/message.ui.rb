# coding: utf-8
#watch __FILE__
class R

  ViewA[SIOC+'InstantMessage'] = ViewA[SIOC+'MicroblogPost'] = -> r,e {
    {href: r.uri, class: :ublog, selectable: true, id: r.uri,
     c: [{_: :span, class: 'date', c: r[Date][0].split('T')[1][0..4]},
         r[Creator].do{|c|
           name = c[0].respond_to?(:uri) ? c[0].uri.split(/[\/#]/)[-1] : c[0].to_s
           e[:label][name] = true
           {class: :creator, name: name, c: {_: :a, href: r.uri, c: name}}},
         {_: :span, class: 'body', c: r[Content]}]}}

  ViewGroup[SIOC+'InstantMessage'] = ViewGroup[SIOC+'MicroblogPost'] = -> d,e {{c: d.map{|u,r|ViewA[SIOC+'InstantMessage'][r,e]}}}

  ViewA[SIOC+'ChatLog'] = -> log,e,d {

    # lines to graph
    graph = {}
    log[LDP+'contains'].map{|line|
      graph[line.uri] = line}

    {class: :chatLog,
     selectable: true, date: log[Date],
     id: URI.escape(log.R.fragment),
     c: [{_: :b, c: "#{log['#hour']}00 #{log[SIOC+'channel']}"},
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

    contained = {}
    [DC+'hasFormat', SIOC+'attachment'].map{|p|
      r[p].justArray.map{|o|
        contained[o.uri] = {'uri' => o.uri, Size => 0} }}
    attache = contained.empty? ? nil : TabularView[contained,e]

    {class: :mail, name: name, id: r.uri, href: href, selectable: :true,
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
         attache
        ]}}

  ViewGroup[SIOC+'ChatLog'] = ViewGroup[SIOC+'BlogPost'] =  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = -> d,e {
    resources = d.resources(e)
    colors = {}
    q = e.q
    arcs = []

    # normalize mtimes to float
    mtimes = d.values.map{|s|
      s[Mtime] || s[Date].justArray.map(&:to_time)
    }.flatten.compact.map(&:to_f)

    # find max/min mtimes
    min = mtimes.min || 0
    max = mtimes.max || 1
    range = (max - min).min(0.1)
    posF = -> time {(time.to_f - min) / range}

    # arcs
    prior = {'uri' => '#'}
    resources.map{|s| # arc source
      if s[SIOC+'has_parent']
        s[SIOC+'has_parent'].justArray.map{|o|
          d[o.uri].do{|t| # arc target
            arc = {source: s.uri, target: o.uri}
            author = s[Creator].justArray[0].do{|c|c.R.fragment}
            arc[:sourceColor] = colors[author] ||= randomColor
            author = t[Creator].justArray[0].do{|c|c.R.fragment}
            arc[:targetColor] = colors[author] ||= randomColor
            s[Mtime].do{|mt| arc[:sourcePos] = posF[mt[0]]}
            t[Mtime].do{|mt| arc[:targetPos] = posF[mt[0]]}
            arcs.push arc }}
      else # ancester unspecified, use temporal ancestor
        arcs.push({source: s.uri,
                   target: prior.uri,
                   sourcePos: posF[s[Date].justArray[0].to_time],
                   targetPos: posF[prior[Date].justArray[0].to_time],
                  })
        prior = s
      end
    }

    # day-labels
    days = {}
    d.values.map{|s|
      s[Date].justArray[0].do{|d|
        day = d[0..9]
        days[day] ||= posF[day.to_time]}}
    days = days.sort_by{|_,m|m}

    # HTML
    [H.css('/css/mail',true),H.css('/css/chat',true),
     {_: :style,
      c: (1..15).map{|depth|
            back = rand(2) == 0
            ".mail .q[depth=\"#{depth}\"] {#{back ? 'background-' : ''}color: #{R.randomColor}; #{back ? '' : 'background-'}color:#000}\n"}},
     {class: :messages, id: :messages,
      c: [e[:Links][:prev].do{|n|
            {class: :prev, id: :first, c: {_: :a, rel: :prev, c: '&larr;', href: CGI.escapeHTML(n.to_s)}}},
          resources.reverse.map{|r|
            ViewA[r[Type].justArray[0].uri][r,e,d]},
          e[:Links][:next].do{|n|
            uri = CGI.escapeHTML(n.to_s)
            {class: :next, id: n, href: uri, next: uri + '#first', c: {_: :a, rel: :next, c: '&rarr;', href: uri}}}
         ]},
     '<br clear=all>',
     {style: "height: 86px;width: 100%;position:fixed;bottom:0;left:0;z-index:1;background-color:#000;opacity: 0.8"},
     days.map{|label,pos|{class: :day, style: "left:#{pos*100}%",c: label}},
     H.js('/js/d3.min'),
     {_: :script, c: "var arcs = #{arcs.to_json};"},
     H.js('/js/timegraph')]}

end
