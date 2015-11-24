# coding: utf-8
class R

  # generic message-view

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
          Facets[d,e], # resources in filterable wrappers
          e[:Links][:next].do{|n|
            {_: :a, href: n, c: '&#9660;', class: :nextPage}}]},
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
       H.js('/js/d3.min'),
       H.js('/js/timegraph',true)] if timegraph)]}

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,e {
    localPath = r.uri == r.R.path
    arc = {source: r.uri, target: r.uri, sourceLabel: r[Label], targetLabel: r[Label]}
    r[Date].do{|t|
      time = t.justArray[0].to_time
      arc[:sourceTime] = arc[:targetTime] = time
      e[:timelabel][time.iso8601[0..9]] = true
    }
    e[:arcs].push arc
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
      [{_: :a, name: name, c: name, href: authorURI ? (localPath ? (c.R.dir+'?set=page') : c.uri) : '#'},' ']}

    discussion = r[SIOC+'has_discussion'].justArray[0].do{|d|
      if e[:thread]
        href = r.uri + '#' + (r.R.path||'') # link to standalone msg
        nil
      else
        href = d.uri + '#' + (r.R.path||'') # link to msg in thread
        {_: :a, class: :discussion, href: href, c: '≡', title: 'show in thread'}
      end}

    # HTML
    {class: :mail, id: r.uri, href: href,
     c: [{class: :header,
          c: [(r[Title].justArray[0].do{|t| {_: :a, class: :title, href: r.uri, c: CGI.escapeHTML(t)}} unless e[:thread]),
              r[To].justArray.map{|o|
                o = o.R
                {_: :a, class: :to, href: localPath ? (o.dir+'?set=page') : o.uri, c: o.fragment || o.path || o.host}}.intersperse({_: :span, class: :sep, c: ','}),
              # reply-of (direct)
              {_: :a, c: ' &larr; ',
               href: r[SIOC+'has_parent'].justArray[0].do{|p|
                 p.uri + '#' + p.uri
               }||'#'},
              author,
              r[Date].do{|d|
                [{_: :a, class: :date,
                  href: r.uri + '#' + r.uri,
                  c: d[0].sub('T',' ')},' ']},
              r[SIOC+'reply_to'].do{|c|
                [{_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'},' ']},
              discussion,
              [DC+'hasFormat', SIOC+'attachment'].map{|p|
                r[p].justArray.map{|o|
                  ['<br>', {_: :a, class: :file, href: o.uri, c: o.R.basename}]}}
             ].intersperse("\n  ")},
         r[Content].justArray.map{|c|{class: :body, c: c}},
         r[WikiText].do{|c|{class: :body, c: Render[WikiText][c]}},'<br>'
        ]}}

end
