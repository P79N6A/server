# coding: utf-8
watch __FILE__
class R

  ViewGroup[SIOCt+'BoardPost'] = ViewGroup[SIOCt+'MailMessage'] = -> d,e {
    colors = {}
    titles = {}
    q = e.q
    big = d.keys.size > 8
    noquote = q.has_key?('noquote') || big

    if noquote # toggle quoted-content
      q.delete 'noquote'
      d.map{|u,r|
        r[Content] = r[Content].justArray.map{|c|
          c.lines.map{|l|l.match(/^<span class='q'/) ? "" : l}.join}}
    else
      q['noquote'] = ''
    end

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
    days.map{|d,m|
      arc = {source: '/'+d.gsub('-','/'),
             target: '/'+yesterday[0].gsub('-','/'),
             sourceName: d,
             sourceColor: '#bbb',
             targetColor: '#bbb',
             arcColor: '#fafafa',
             sourcePos: (max - m) / range,
             targetPos: (max - yesterday[1]) / range,
            }
      yesterday = [d,m]
      arcs.push arc
    }
    d.values.map{|s| # direct-reference arcs
      s[SIOC+'has_parent'].justArray.map{|o|
        arc = {source: s.uri, target: o.uri}
        author = s[Creator][0].R.fragment
        arc[:sourceName] = author unless colors[author] # show each name once
        arc[:sourceColor] = colors[author] ||= cs
        s[Mtime].do{|t|
          pos = (max - t[0].to_f) / range
          arc[:sourcePos] = pos
        }
        d[o.uri].do{|o| # target also exists in loaded graph
          author = o[Creator][0].R.fragment
          arc[:targetName] = author unless colors[author]
          arc[:targetColor] = colors[author] ||= cs
          o[Mtime].do{|t|
            pos = (max - t[0].to_f) / range
            arc[:targetPos] = pos
          }
        }
        arcs.push arc
      }}

    [H.css('/css/mail',true),
     {_: :style,
      c: colors.map{|name,c| "a[name=\"#{name}\"] {color: #{c}}\n"}},
     ({_: :a, href: q.qs, c: noquote ? '&#x27eb;' : '&#x27ea;', title: "hide quotes", class: :noquote} if !big),
     d.resources(e).reverse.map{|r| # show message
       [{class: :mail, id: r.uri,
         c: [
          r[Title].do{|t|
            title = t[0].sub ReExpr, ''
            if titles[title] # only shop topic if changed
              nil
            else
              titles[title] = true
              [{_: :a, class: :title, href: r.uri, c: title},'<br>']
            end
          },
          r[Creator].do{|c|
            author = c[0].R.fragment
            {_: :a, name: author, href: c[0].R.dirname, c: author}}, ' &rarr; ',
          r[SIOC+'has_parent'].do{|ps|
            ps.map{|p| # replied-to messages
              d[p.uri].do{|r| # target msg
                author = r[Creator][0].R.fragment
                {_: :a, name: author, href: '#'+p.uri, c: author}} ||
              {_: :a, class: :msg, href: p.uri, c: '&#9993;'}
            }.intersperse(' ')}, ' ',
          r[To].justArray.map{|o|
            {_: :a, class: :to, href: o.R.dirname, c: o.R.fragment} unless colors[o.R.fragment]}.intersperse(' '), ' ',
          r[SIOC+'reply_to'].do{|c|
            [{_: :a, class: :create, href: c.justArray[0].uri, c: ['&#x270e;','&#x270f;','&#x2710;'][rand(3)]},' ']},
          r[Date].do{|d|
            {_: :a, class: :ts, href: r.uri, c: d[0].sub('T',' ')}},
          r[SIOC+'has_discussion'].do{|d|
            {_: :a, class: :discussion, href: d[0].uri + '#' + r.uri, c: '≡'} unless e[:thread]},
          '<br>', r[Content],
          [DC+'hasFormat', SIOC+'attachment'].map{|p|
            r[p].justArray.map{|o|
              {_: :a, class: :attached, href: o.uri, c: o.R.basename}}}]},'<br>']},
     H.js('/js/d3.v3.min'), {_: :script, c: "var links = #{arcs.to_json};"},
     H.js('/js/mail',true)]}

end
