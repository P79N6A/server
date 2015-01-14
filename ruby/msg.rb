# coding: utf-8
#watch __FILE__
class R

  ViewGroup[SIOCt+'BoardPost'] = ViewGroup[SIOCt+'MailMessage'] = -> d,e {
    colors = {}
    titles = {}
    q = e.q
    big = d.keys.size > 8 && !q.has_key?('raw')
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
             sourceColor: '#ccc',
             targetColor: '#ccc',
             arcColor: '#fafafa',
             sourceSize: 128,
             sourcePos: (max - m) / range,
             targetPos: (max - yesterday[1]) / range,
            }
      yesterday = [d,m]
      arcs.push arc
    }
    d.values.map{|s|
      s[SIOC+'has_parent'].justArray.map{|o| # source -> target
        d[o.uri].do{|t| # target
          arc = {source: s.uri, target: o.uri}
          author = s[Creator][0].R.fragment
          arc[:sourceName] = author unless colors[author]
          arc[:sourceColor] = colors[author] ||= cs
          author = t[Creator][0].R.fragment
          arc[:targetName] = author unless colors[author]
          arc[:targetColor] = colors[author] ||= cs
          s[Mtime].do{|mt|
            pos = (max - mt[0].to_f) / range
            arc[:sourcePos] = pos}
          t[Mtime].do{|mt|
            pos = (max - mt[0].to_f) / range
            arc[:targetPos] = pos}
          arcs.push arc }}}
    [H.css('/css/mail',true),
     {_: :style,
      c: colors.map{|name,c| "[name=\"#{name}\"] {background-color: #{c}}\n"}},
     ({_: :a, href: q.qs, c: noquote ? '&#x27eb;' : '&#x27ea;', title: "hide quotes", class: :noquote} if !big),
     {class: :messages, c: d.resources(e).reverse.map{|r| # message
        {class: :mail, id: r.uri,
         c: [r[Title].do{|t|
               title = t[0].sub ReExpr, ''
               if titles[title] # only shop topic if changed
                 nil
               else
                 titles[title] = true
                 {_: :a, class: :title, href: r.uri, c: title}
               end},
             {class: :header,
              c: [r[Creator].do{|c|
                    author = c[0].R.fragment
                    {class: :corner, c: {_: :a, class: :author, name: author, href: c[0].R.dirname, c: author}}},
                  r[To].justArray.map{|o|
                    {_: :a, class: :to, href: o.R.dirname, c: o.R.fragment} unless colors[o.R.fragment]}.intersperse(' '), ' ',
                  r[SIOC+'has_parent'].do{|ps|
                    ps.map{|p| # replied-to messages
                      d[p.uri].do{|r| # target msg
                        c = r[Creator][0].R.fragment
                        {_: :a, name: c, href: '#'+p.uri, c: c}} ||
                      {_: :a, class: :msg, href: p.uri, c: '&#9993;'}
                    }.intersperse(' ')}, ' ',
                  r[SIOC+'reply_to'].do{|c|
                    [{_: :a, class: :create, href: c.justArray[0].uri, c: ['&#x270e;','&#x270f;','&#x2710;'][rand(3)]},' ']},
                  r[Date].do{|d|
                    {_: :a, class: :ts, href: r.uri, c: d[0].sub('T',' ')}},
                  r[SIOC+'has_discussion'].do{|d|
                    {_: :a, class: :discussion, href: d[0].uri + '#' + r.uri, c: '≡'} unless e[:thread]}]},
             {class: :body, c: r[Content]},
             [DC+'hasFormat', SIOC+'attachment'].map{|p|
               r[p].justArray.map{|o|
                 {_: :a, class: :attached, href: o.uri, c: o.R.basename}}}]}}},
     H.js('/js/d3.v3.min'), {_: :script, c: "var links = #{arcs.to_json};"},
     H.js('/js/mail',true)]}

end
