# coding: utf-8
watch __FILE__
class R

  ViewA[Content] = -> r,e {r[Content]}
  ViewA['default'] = -> r,e {r.html}

  ViewA[Container] = ViewA[Stat+'Directory'] = -> r,e {
    re = r.R
    path = (re.path||'').t
    size = Stat + 'size'
    group = e.q['group']
    sort = e.q['sort'].do{|p|p.expand} || size
    sortType = [size].member?(sort) ? :to_i : :to_s
    [{class: :container, style: "background-color: #{R.cs}", id: re.fragment,
      c: [{_: :a, class: :uri, href: re.uri,
           c: r[Label] || (re.path=='/' ? re.host : re.abbr)},"<br>\n",
          r[LDP+'contains'].do{|c|
            sizes = c.map{|r|r[size] if r.class == Hash}.flatten.compact
            maxSize = sizes.max
            sized = !sizes.empty? && maxSize > 1
            width = maxSize.to_s.size
            c.sort_by{|i|
              ((i.class==Hash && i[sort] || i.uri).justArray[0]||0).send sortType}.
              send((sized || sort==Date) ? :reverse : :id).map{|r|
              data = r.class == Hash
              [{_: :a, href: r.R.uri, class: :member,
                c: [(if data && sized && r[size]
                     s = r[size].justArray[0]
                     [{_: :span, class: :size, c: (s > 1 ? "%#{width}d" % s : ' '*width).gsub(' ','&nbsp;')}, ' ']
                     end),
                    ([r[Date],' '] if data && sort==Date),
                    data && (r[Title] || r[Label]) || r.R.abbr[0..64]
                   ]}, data ? "<br>\n" : " "]}},
          (if e.R.path == path && GREP_DIRS.find{|p|path.match p}
           {_: :form,
            c: [{_: :input, name: :q},
                {_: :input, type: :hidden, name: :set, value: :grep}]}
           end)
         ]}]}

  ViewGroup[LDP+'Resource'] = -> g,e {
    [(H.css '/css/page', true),
     (H.js '/js/pager', true),
     (H.js '/js/mu', true),
     g.map{|u,r|
       ViewA[LDP+'Resource'][r,e]}]}

  ViewA[LDP+'Resource'] = -> u,e {
    label = -> r {(r.R.query_values.do{|q|q['offset']} || r).R.stripDoc.path.gsub('/',' ')}
    prev = u[Prev]
    nexd = u[Next]
    [Prev,Next,Type].map{|p|u.delete p}
    [prev.do{|p|
       {_: :a, rel: :prev, href: p.uri, c: ['↩ ', label[p]], title: '↩ previous page'}},
     nexd.do{|n|
       {_: :a, rel: :next, href: n.uri, c: [label[n], ' →'], title: '→ next page'}},
     ViewA['default'][u,e]]}

  Tabulator = -> r,e {
    src = '//linkeddata.github.io/tabulator/'
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.js  '/js/tabr'),
     (H.css src + 'tabbedtab'),
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  ViewGroup[Stat+'Directory'] = ViewGroup[Stat+'File'] = ViewGroup[RDFs+'Resource'] = -> d,env {
    mtime = Stat+'mtime'
    keys = [Stat+'size', 'uri', mtime, LDP+'contains', Type]
    path = env['REQUEST_PATH']
    ascending = env.q.has_key? 'ascending'
    env.q['sort'] ||= mtime
    sort = env.q['sort'].expand
    sort = mtime if sort == Date
    sort = 'uri' if sort == Title
    sortType = [mtime,Stat+'size'].member?(sort) ? :to_i : :to_s
    sortLabel = sort.shorten.split(':')[-1] + ' ↨'
    s_ = case sort # next sort-predicate
         when Stat+'size'
           'dc:date'
         when Date
           'dc:title'
         when Stat+'mtime'
           'dc:title'
         else
           'stat:size'
         end
    sortQ  = env.q.merge({'sort' => s_}).qs # querystring w/ next sort-order
    qs = env.q
    if ascending
      qs.delete 'ascending'
    else
      qs['ascending'] = 'a'
    end

    this = d.delete env.uri if d[env.uri]
    if up = d['..']
      d.delete '..'
    end

    entries = d.values.sort_by{|v|(v[sort].justArray[0] || 0).send sortType}.send(ascending ? :id : :reverse)

    [({_: :a, class: :up, href: up.uri, title: Pathname.new(path).parent.basename, c: '&uarr;'} if up),
     (ViewA[Container][this,env] if this),
     {_: :a, class: :sort, c: sortLabel, href: sortQ, title: s_},
     (if entries.size == 1 # skip tabular view if only one
      r = entries[0]
      type = r.types.find{|t|ViewA[t]}
      ViewA[type ? type : 'default'][r,env]
      end),
     ({_: :table, class: :ls,
       c: [{_: :tr, c: keys.map{|k|
              {_: :th, class: (k == sort ? 'this' : 'that'),
               property: k, c: {_: :a, href: qs.merge({'sort' => k.shorten}).qs, c: k.R.abbr}}}},

           entries.map{|e|
             types = e.types
             container = types.include?(Container)
             directory = types.include?(Stat+'Directory')
             containerType = container || directory
             file = types.include?(Stat+'File')

             {_: :tr, uri: e.uri,
              c: keys.map{|k|
                {_: :td, property: k, class: (k == sort ? 'this' : 'that'),
                 c: case k
                    when 'uri'
                      unless containerType
                        {_: :a, href: (file ? e.R.stripDoc.a('.html') : e).uri,
                         c: e[Label]||e[Title]||URI.unescape(e.R.abbr)}
                      end
                    when mtime
                      e[k].do{|t| Time.at(t[0]).iso8601.sub /\+00:00$/,''}
                    when Type
                      if containerType
                        {_: :a, class: :dir, href: e.uri+'?set=page', c: '►'}
                      elsif file
                        {_: :a, class: :file, href: e.uri, c: '█'}
                      elsif types.include?(RDFs+'Resource')
                        {_: :a, class: :resource, href: e.uri, c: '■'}
                      else
                        e[k].html
                      end
                    when LDP+'contains'
                      if containerType
                        ViewA[Container][e,env]
                      elsif types.include?(DC+'Image')
                        ShowImage[e.uri]
                      end
                    when Stat+'size'
                      e[Stat+'size'] unless e[LDP+'contains']
                    else
                      e[k].html
                    end}}}}]} unless entries.size < 2),
     (H.css '/css/ls',true),
     (H.css '/css/container',true),
     (H.js '/js/ls',true)]}

  [Container, 'default'].map{|type|
    ViewGroup[type] = -> g,e {g.map{|u,r|ViewA[type][r,e]}}}


  def triplrAudio &f
    uri = '#'  + URI.escape(path)
    yield uri, Type, R[DC+'Sound']
    yield uri, Title, basename
  end
   
  ViewGroup[DC+'Sound'] = -> g,e {
    [{_: :audio, id: :audio, style: 'width:100%', controls: true}, H.js('/js/audio'),
     ViewA[Container][{'uri' => '#sounds', LDP+'contains' => g.values },e]]}


end
