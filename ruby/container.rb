# coding: utf-8
#watch __FILE__
class R

  Summarize = -> g,e {
    groups = {}
    g.map{|u,r|
      r.types.map{|type|
        if v = Abstract[type]
          groups[v] ||= {}
          groups[v][u] = r
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}}

  ViewA[Content] = -> r,e {r[Content]}
  ViewA['default'] = -> r,e {[r.html, H.once(e, 'default', (H.css '/css/html', true))]}

  ViewA[Container] = -> r,e {
    re = r.R
    path = (re.path||'').t
    size = Stat + 'size'
    group = e.q['group']
    sort = e.q['sort'].do{|p|p.expand} || size
    sortType = [size].member?(sort) ? :to_i : :to_s
    sortLabel = sort.shorten.split(':')[-1] + ' ↨'
    s_ = case sort
         when size
           'dc:date'
         when Date
           'dc:title'
         when Title
           'stat:size'
         else
           'stat:size'
         end
    sortQ  = '?sort='+s_
    sortQ += "&group=#{group}" if group && %w{rdf:type}.member?(group)

    [{class: :container, style: "background-color: #{R.cs}",
      c: [{_: :a, class: :uri, c: r[Label] || (re.path=='/' ? re.host : re.abbr), href: re.uri},
          H.once(e,:sortButton,{_: :a, class: :sort, c: sortLabel, href: sortQ, title: s_}), "<br>\n",
          r[LDP+'contains'].do{|c|
            sizes = c.map{|r|r[size] if r.class == Hash}.flatten.compact
            maxSize = sizes.max
            sized = !sizes.empty? && maxSize > 1
            width = maxSize.to_s.size
            c.sort_by{|i|((i.class==Hash && i[sort] || i.uri).justArray[0]||0).send sortType}.send((sized || sort==Date) ? :reverse : :id).map{|r|
              data = r.class == Hash
              {_: :a, href: r.R.uri, class: :member,
               c: [(if data && sized && r[size]
                    s = r[size].justArray[0]
                    [{_: :span, class: :size, c: (s > 1 ? "%#{width}d" % s : ' '*width).gsub(' ','&nbsp;')}, ' ']
                    end),
                   ([r[Date],' '] if data && sort==Date),
                   data && (r[Title] || r[Label]) || r.R.abbr[0..64],
                   ("<br>\n" if data)
                  ]}}.intersperse(" ")},
          ({_: :form,
            c: [{_: :input, name: :q},
                {_: :input, type: :hidden, name: :set, value: :grep}]} if e.R.path == path && GREP_DIRS.find{|p|path.match p})
         ]},{_: :p, style: 'display: inline'},
     (H.once e, 'container', (H.css '/css/container',true))]}

  ViewA[LDP+'Resource'] = -> u,e {
    offset = -> r {
      (r.R.query_values.do{|q|q['offset']} || r).R.stripDoc.path.gsub('/',' ')}
    [u[Prev].do{|p|{_: :a, rel: :prev, href: p.uri, c: ['↩ ', offset[p]], title: '↩ previous page'}},
     u[Next].do{|n|{_: :a, rel: :next, href: n.uri, c: [offset[n], ' →'], title: '→ next page'}},
     ([(H.css '/css/page', true), (H.js '/js/pager', true), (H.once e,:mu,(H.js '/js/mu', true))] if u[Next]||u[Prev])]}

  # multiple types mapped to one view function - "ls" of files/dirs/generic-resources
  ViewGroup[Stat+'Directory'] = ViewGroup[Stat+'File'] = ViewGroup[RDFs+'Resource'] = -> d,env {
    mtime = Stat+'mtime'
    keys = [Stat+'size', 'uri', mtime, LDP+'contains', Type]
    path = env['REQUEST_PATH']
    asc = env.q.has_key? 'asc'
    env.q['sort'] ||= mtime
    sort = env.q['sort'].expand
    sort = mtime if sort == Date
    sort = 'uri' if sort == Title
    sortType = [mtime,Stat+'size'].member?(sort) ? :to_i : :to_s

    # . and ..
    this = d.delete env.uri if d[env.uri]
    if d['..']
      d.delete '..'
      up = true
    end

    entries = d.values.sort_by{|v|(v[sort].justArray[0] || 0).send sortType}.send(asc ? :id : :reverse)
    [({_: :a, class: :up, href: '..', title: Pathname.new(path).parent.basename, c: '&uarr;'} if up), # ..
     (ViewA[Container][this,env] if this),                                                            # .
     ({_: :table, class: :ls,
       c: [{_: :tr, c: keys.map{|k|
              {_: :th, class: (k == sort ? 'this' : 'that'),
               property: k, c: {_: :a, href: path+'?sort='+k.shorten+(asc ? '' : '&asc=asc'), c: k.R.abbr}}}},

           entries.map{|e|
             types = e.types
             container = types.include?(Container)
             directory = types.include?(Stat+'Directory')
             file = types.include?(Stat+'File')

             {_: :tr, uri: e.uri,
              c: keys.map{|k|
                {_: :td, property: k, class: (k == sort ? 'this' : 'that'),
                 c: case k
                    when 'uri'
                      {_: :a, href: (file ? e.R.stripDoc.a('.html') : e).uri, c: e[Label]||e[Title]||URI.unescape(e.R.abbr)} unless container || directory
                    when mtime
                      e[k].do{|t| Time.at(t[0]).iso8601.sub /\+00:00$/,''}
                    when Type
                      if directory || container
                        {_: :a, class: :dir, href: e.uri, c: '►'}
                      elsif types.include?(DC+'Image')
                        ShowImage[e.uri]
                      elsif types.size==1 && types[0]==RDFs+'Resource'
                        {_: :a, class: :resource, href: e.uri, c: '■'}
                      elsif file
                        {_: :a, class: :file, href: e.uri, c: '█'}
                      else
                        e[k].html
                      end
                    when LDP+'contains'
                      ViewA[Container][e,env] if container || directory
                    when Stat+'size'
                      e[Stat+'size'] unless e[LDP+'contains']
                    else
                      e[k].html
                    end}}}}]} unless entries.empty?),
     (H.css '/css/ls',true), (H.js '/js/ls',true)]}

  [Container, LDP+'Resource', 'default'].map{|type|
    ViewGroup[type] = -> g,e {g.map{|u,r|ViewA[type][r,e]}}}

end
