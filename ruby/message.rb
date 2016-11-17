# coding: utf-8
class R

  ViewGroup[SIOC+'BlogPost'] =  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = ViewGroup[SIOC+'ChatLog'] = -> d,e {
    e[:arcs] = []
    e[:day] = {}
    e.q['a'] ||= (e[:thread] ? Creator : 'sioc:addressed_to')

    # find timegraph arcs
    d.values.map{|s|
      if s[SIOC+'has_parent']
        s[SIOC+'has_parent'].justArray.map{|o|
          d[o.uri].do{|t| # arc target
            sLabel = s[Creator].justArray[0].do{|c|c.R.fragment}
            tLabel = t[Creator].justArray[0].do{|c|c.R.fragment}
            e[:label][sLabel] = true
            e[:label][tLabel] = true
            source = s.uri.gsub(/[^a-zA-Z0-9]/,'')
            target = o.uri.gsub(/[^a-zA-Z0-9]/,'')
            e[:arcs].push({source: source, target: target, sourceLabel: sLabel, targetLabel: tLabel})}}
      end}
    # labels
    (1..15).map{|depth| e[:label]["quote"+depth.to_s] = true}

    [([{_: :script, c: "var arcs = #{e[:arcs].to_json};"},
       H.js('/js/d3.min'),
       H.js('/js/timegraph',true),
       {class: :timegraph,c: {_: :svg}}
      ] if e[:arcs].size > 1),
     {class: :msgs,
      c: [(d.values[0][Title].justArray[0].do{|t|
             title = t.sub ReExpr, ''
             [{_: :h3,class: :title, c: CGI.escapeHTML(title)},'<br>']} if e[:thread]),
          d.map{|uri,msg|
            type = msg.types.find{|t|ViewA[t]}
            ViewA[type ? type : BasicResource][msg,e]
          }]}]}

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,e {
    localPath = r.uri == r.R.path
    navigateHeaders = r.R.path == e.R.path
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
      [{_: :a, name: name, c: name, href: authorURI ? (localPath ? c.R.dir : c.uri) : '#'}.update(navigateHeaders ? {id: 'h'+rand.to_s.h} : {}),' ']}

    discussionURI = r[SIOC+'has_discussion'].justArray[0].do{|d|d.uri+'#'+r.R.hierPart}

    # HTML
    [{class: :mail,
     c: [[(r[Title].justArray[0].do{|t|
             {_: :a, class: :title, href: discussionURI || r.uri, c: CGI.escapeHTML(t.to_s)}.update(navigateHeaders ? {id: 'h'+rand.to_s.h} : {})} unless e[:thread]),
          r[To].justArray.map{|o|
            o = o.R
            {_: :a, class: :to, href: localPath ? o.dir : o.uri, c: o.fragment || o.path || o.host}.update(navigateHeaders ? {id: 'h'+rand.to_s.h} : {})}.intersperse({_: :span, class: :sep, c: ','}),
          # reply-of (direct)
          {_: :a, c: ' &larr; ',
           href: r[SIOC+'has_parent'].justArray[0].do{|p|
             p.uri + '#' + p.uri
           }||'#'},
          author,
          r[Date].do{|d|[{_: :a, class: :date, href: r.uri, c: d[0].sub('T',' ')},' ']},
          r[SIOC+'reply_to'].do{|c|
            [{_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'}.update(navigateHeaders ? {id: 'h'+rand.to_s.h} : {}),' ']},
         ].intersperse("\n"),
         r[Content].justArray.map{|c|
           {class: :body, c: c}},
         r[WikiText].do{|c|{class: :body, c: Render[WikiText][c]}},
         [DC+'hasFormat', SIOC+'attachment'].map{|p| r[p].justArray.map{|o|['<br>', {_: :a, class: :file, href: o.uri, c: o.R.basename}]}},
        ]}.update(navigateHeaders ? {} : {id: r.uri.gsub(/[^a-zA-Z0-9]/,''), href: href}),
     ('<br>' if r.types.member?(SIOC+'MailMessage'))
    ]}

end
