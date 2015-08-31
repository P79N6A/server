# coding: utf-8
#watch __FILE__
class R

  ViewA[SIOC+'InstantMessage'] = ViewA[SIOC+'MicroblogPost'] = -> r,e {
    {href: r.uri, class: :ublog, selectable: true, id: r.uri,
     c: [{_: :span, class: 'date', c: r[Date][0].split('T')[1][0..4]},
         r[Creator].do{|c|
           name = c[0].respond_to?(:uri) ? c[0].uri.split(/[\/#]/)[-1] : c[0].to_s
           e[:label][name] = true
           {class: :creator, c: {_: :a, href: r.uri, name: name, c: name}}},
         {_: :span, class: 'body', c: r[Content]}]}}

  ViewGroup[SIOC+'InstantMessage'] = ViewGroup[SIOC+'MicroblogPost'] = -> d,e {
    {style: 'padding-top: .3em', c: d.map{|u,r|
       ViewA[SIOC+'InstantMessage'][r,e]}}}

  ViewA[SIOC+'ChatLog'] = -> log,e {
    posF = -> time {
#      puts((time.to_f - e[:tgmin]) / e[:tgrng])
      (time.to_f - e[:tgmin]) / e[:tgrng]
    }
    logDate = posF[log[Date].justArray[0].to_time],
    graph = {}
    log[LDP+'contains'].map{|line|
      e[:arcs].push({source: line.uri, sourcePos: posF[line[Date].justArray[0].to_time],
                     target: log.uri, targetPos: logDate, weight: 2.0})
      graph[line.uri] = line}

    {class: :chatLog, selectable: true, date: log[Date],
     id: URI.escape(log.R.fragment),
     c: [{_: :b, c: "#{log['#hour']}00 #{log[SIOC+'channel']}"},
         ViewGroup[SIOC+'InstantMessage'][graph,e]]}}

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,e {
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
      r[p].justArray.map{|o| contained[o.uri] = {'uri' => o.uri}}}
    attache = contained.empty? ? nil : TabularView[contained,e]

    {class: :mail, id: r.uri, href: href, selectable: :true,
     c: [(r[Title].justArray[0].do{|t|
            {class: :title, c: {_: :a, class: :title, href: r.uri, c: CGI.escapeHTML(t)}}} unless e[:thread]),
         {class: :header,
          c: [r[To].justArray.map{|o|
                o = o.R
                {_: :a, class: :to, href: o.uri, c: o.fragment || o.path || o.host}}.intersperse({_: :span, class: :sep, c: ','}),
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
    arcs = e[:arcs] = []

    # normalize mtimes to float
    mtimes = d.values.map{|s|
      s[Mtime] || s[Date].justArray.map(&:to_time)
    }.flatten.compact.map(&:to_f)

    #  max/min mtimes
    e[:tgmin] = min = mtimes.min || 0
    e[:tgmax] = max = mtimes.max || 1
    e[:tgrng] = range = (max - min).min(0.1)
    posF = -> time {(time.to_f - min) / range}

    # arcs
    prior = {'uri' => '#'}
    resources.map{|s| # arc source
      if s[SIOC+'has_parent']
        s[SIOC+'has_parent'].justArray.map{|o|
          d[o.uri].do{|t| # arc target
            sLabel = s[Creator].justArray[0].do{|c|c.R.fragment}
            tLabel = t[Creator].justArray[0].do{|c|c.R.fragment}
            e[:label][sLabel] = true
            e[:label][tLabel] = true
            arc = {source: s.uri, target: o.uri, sourceLabel: sLabel, targetLabel: tLabel}
            s[Mtime].do{|mt| arc[:sourcePos] = posF[mt[0]]}
            t[Mtime].do{|mt| arc[:targetPos] = posF[mt[0]]}
            arcs.push arc }}
      else # unspecified, use temporal relation
        arcs.push({source: s.uri,
                   target: prior.uri,
                   sourcePos: posF[s[Date].justArray[0].to_time],
                   targetPos: posF[prior[Date].justArray[0].to_time],
                  })
        prior = s
      end
    }

    # labels
    days = {}
    d.values.map{|s|
      s[Date].justArray[0].do{|d|
        day = d[0..9]
        days[day] ||= posF[day.to_time]}}
    days = days.sort_by{|_,m|m}
    (1..15).map{|depth| e[:label]["quote"+depth.to_s] = true}

    defaultFilter = e[:thread] ? Creator : 'sioc:addressed_to'
    e.q['a'] ||= defaultFilter
    tg = {id: :timegraph,
          c: [{_: :svg},
              days.map{|label,pos|
                {class: :day, style: "top:#{100 - pos*100}%", c: label}}]}

    # HTML
    [H.css('/css/mail',true),
     H.css('/css/chat',true),
     {class: :msgs,
      c: [(resources[0][Title].justArray[0].do{|t|
             {_: :h1, c: CGI.escapeHTML(t.sub(ReExpr,''))}} if e[:thread]),
          Facets[d,e]]}, # resources in filterable wrapper-nodes
     (e[:sidebar].push(tg); nil),
     ([{_: :script, c: "var arcs = #{e[:arcs].to_json};"},
       H.js('/js/d3.min'),
       H.js('/js/timegraph',true)] unless d.keys.size==1)]}

end
