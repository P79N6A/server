# coding: utf-8
#watch __FILE__
class R

  # generic message-view

  ViewGroup[SIOC+'ChatLog'] = ViewGroup[SIOC+'BlogPost'] =  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = -> d,e {
    e[:arcs] = []
    e[:day] = {}
    e.q['a'] ||= (e[:thread] ? Creator : 'sioc:addressed_to')
    e.q['reverse'] ||= true

    # find timegraph arcs
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

    resources = Facets[d,e]

    # scale time-values
    times = e[:arcs].map{|a|[a[:sourceTime],a[:targetTime]]}.flatten.compact.map(&:to_f)
    min = times.min || 0
    max = times.max || 1
    range = (max - min).min(0.1)
    e[:arcs].map{|a|
      a[:sourcePos] = (a[:sourceTime].to_f - min) / range
      a[:targetPos] = (a[:targetTime].to_f - min) / range
      a.delete :sourceTime
      a.delete :targetTime }
    timegraph = e[:arcs].size > 1

    # HTML
    [([{_: :script, c: "var arcs = #{e[:arcs].to_json};"},
       H.js('/js/d3.min'),
       H.js('/js/timegraph',true),
       {id: :timegraph,
        c: {_: :svg,
            c: e[:day].map{|l,_|
              %w{00 06 12 18}.map{|hour|
                day = hour == '00'
                ts = l + hour + ':00'
                pos = (ts.to_time.to_f - min) / range * 100
                x = pos.to_s + '%'
                [{_: :line, stroke: day ? '#fff' : '#666',
                  y1: 0, y2: '88%', x1: x, x2: x},
                 {_: :text, 'font-size'  =>'.8em',
                  fill: day ? '#111' : '#888',
                  c: (day ? ts[0..9] : ts[11..12]),
                  dy: day ? 1 : 8, y: 0, x: x,
                  onclick: day ? "window.location.href=\"/#{ts[0..9].gsub('-','/')}/\"" : ''}]}
            }}}
      ] if timegraph),
     {class: :msgs,
      c: [(d.values[0][Title].justArray[0].do{|t|
             title = t.sub ReExpr, ''
             {_: :h1, c: CGI.escapeHTML(title)}} if e[:thread]),
          resources,
          e[:Links][:next].do{|n|
            {_: :a, href: n, c: '&#9660;', class: :nextPage}}]}]}

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,e {
    localPath = r.uri == r.R.path
    r[Date].do{|t| e[:day][t.justArray[0].to_time.iso8601[0..10]] = true }
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
      [{_: :a, name: name, c: name, href: authorURI ? (localPath ? c.R.dir : c.uri) : '#'},' ']}

    discussionURI = r[SIOC+'has_discussion'].justArray[0].do{|d|d.uri+'#'+r.R.hierPart}

    # HTML
    [{class: :mail, id: r.uri.gsub(/[^a-zA-Z0-9]/,''), href: href,
      c: [{class: :header,
           c: [(r[Title].justArray[0].do{|t|
                  {_: :a, class: :title, href: discussionURI || r.uri, c: CGI.escapeHTML(t.to_s)}} unless e[:thread]),
               r[To].justArray.map{|o|
                 o = o.R
                 {_: :a, class: :to, href: localPath ? o.dir : o.uri, c: o.fragment || o.path || o.host}}.intersperse({_: :span, class: :sep, c: ','}),
               # reply-of (direct)
               {_: :a, c: ' &larr; ',
                href: r[SIOC+'has_parent'].justArray[0].do{|p|
                  p.uri + '#' + p.uri
                }||'#'},
               author,
               r[Date].do{|d|[{_: :a, class: :date, href: r.uri, c: d[0].sub('T',' ')},' ']},
               r[SIOC+'reply_to'].do{|c|
                 [{_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'},' ']},
              ].intersperse("\n  ")},
          r[Content].justArray.map{|c|{class: :body, c: c}},
          r[WikiText].do{|c|{class: :body, c: Render[WikiText][c]}},
          [DC+'hasFormat', SIOC+'attachment'].map{|p| r[p].justArray.map{|o|['<br>', {_: :a, class: :file, href: o.uri, c: o.R.basename}]}},
         ]},'<br>']}

end
