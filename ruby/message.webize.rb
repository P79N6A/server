# coding: utf-8
#watch __FILE__
class R

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

  MessagePath = -> id{ # rfc2822 Message-ID -> /path
    msg, domainname = id.downcase.sub(/^</,'').sub(/>.*/,'').gsub(/[^a-zA-Z0-9\.\-@]/,'').split '@'
    dname = (domainname||'').split('.').reverse
    case dname.size
    when 0
      dname.unshift 'none','nohost'
    when 1
      dname.unshift 'none'
    end
    tld = dname[0]
    domain = dname[1]
    ['', 'address', tld, domain[0], domain, *dname[2..-1], '@', id.h[0..1], msg].join('/')}

  AddrPath = ->address{ # email-address -> /path
    address = address.downcase
    person, domainname = address.split '@'
    dname = (domainname||'').split('.').reverse
    tld = dname[0]
    domain = dname[1] || 'localdomain'
    ['', 'address', tld, domain[0], domain, *dname[2..-1], person,''].join('/') + person + '#' + person}

  GET['/address'] = -> e,r {e.justPath.response} # free hostname

  GET['/thread'] = -> e,r { # reconstruct thread
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of','sioc:reply_of', m # recursive walk
    return E404[e,r] if m.empty?                                       # nothing found?

    # thread identity
    r[:Response]['ETag'] = [m.keys.sort, r.format].h
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'

    e.condResponse ->{ r[:thread] = true
      # add thread title to document
      m.values.find{|r|
        r.class == Hash && r[Title]}.do{|t|
        title = t.justArray[0]
        r[:title] = title.sub ReExpr, '' if title.class==String}
      # render RDF or HTML
      Render[r.format].do{|p|p[m,r]} ||
        m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)
    }}

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,e {
    localPath = r.uri == r.R.path
    arc = {source: r.uri, target: r.uri, sourceLabel: r[Label], targetLabel: r[Label]}
    r[Date].do{|t|
      time = t.justArray[0].to_time
      arc[:sourceTime] = arc[:targetTime] = time
      e[:timelabel][time.iso8601[0..9]] = true
    }
    e[:arcs].push arc
    mail = r.types.member?(SIOC+'MailMessage')
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
      [{_: :a, name: name, c: name, href: authorURI ? (localPath ? (c.R.dir+'?set=first-page') : c.uri) : '#'},' ']}

    discussion = r[SIOC+'has_discussion'].justArray[0].do{|d|
      if e[:thread]
        href = r.uri + '#' + (r.R.path||'') # link to standalone msg
        nil
      else
        href = d.uri + '#' + (r.R.path||'') # link to msg in thread
        {_: :a, class: :discussion, href: href, c: '≡', title: 'show in thread'}
      end}

    # HTML
    [{class: :mail, id: r.uri, href: href, selectable: :true,
     c: [(r[Title].justArray[0].do{|t|
            {class: :title, c: {_: :a, class: :title, href: r.uri, c: CGI.escapeHTML(t)}}} unless e[:thread]),
         {class: :header,
          c: [r[To].justArray.map{|o|
                o = o.R
                {_: :a, class: :to, href: localPath ? (o.dir+'?set=first-page') : o.uri, c: o.fragment || o.path || o.host}}.intersperse({_: :span, class: :sep, c: ','}),
              # reply-target message
              {_: :a, c: ' &larr; ',
               href: r[SIOC+'has_parent'].justArray[0].do{|p|
                 p.uri + '#' + p.uri
               }||'#'},
              author,
              # timestamp
              r[Date].do{|d|
                [{_: :a, class: :date,
                  href: r.uri + '#' + r.uri,
                  c: d[0].sub('T',' ')},' ']},
              r[SIOC+'reply_to'].do{|c|
                [{_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'},' ']},
              discussion
             ].intersperse("\n  ")},
         r[Content].justArray.map{|c|
           {_: mail ? :pre : :div, class: :body, c: c}},
         r[WikiText].do{|c|{class: :body, c: Render[WikiText][c]}},
         [DC+'hasFormat', SIOC+'attachment'].map{|p| r[p].justArray.map{|o|{_: :a, name: name, class: :file, href: o.uri, c: o.R.basename}}},
        ]},'<br>']}

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
             {_: :h1, c: CGI.escapeHTML(t.sub(ReExpr,''))}} if e[:thread]),
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
                              [{_: :line, stroke: '#fff', 'stroke-dasharray' => '2,2', x1: 0, x2: '100%', y1: y, y2: y},
                               {_: :text, fill: '#fff', 'font-size'  =>'.8em',c: l.sub('T',' '), dy: -3, x: 0, y: y}
                              ]}}}) if timegraph

      nil),
     ([{_: :script, c: "var arcs = #{e[:arcs].to_json};"},
       H.js('/js/d3.min'), H.js('/js/timegraph',true)] if timegraph)]}

end
