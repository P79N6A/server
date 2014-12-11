# coding: utf-8
watch __FILE__
class R

  ViewA[Content] = -> r,e {r[Content]}

  ViewA[Container] = ViewA[Directory] = -> r,e {
    re = r.R
    path = (re.path||'').t
    size = Stat + 'size'
    group = e.q['group']
    sort = e.q['sort'].do{|p|p.expand} || size
    sortType = [size].member?(sort) ? :to_i : :to_s
    [{class: :container, style: "background-color: #{R.cs}", id: re.fragment,
      c: [{_: :a, class: :uri, href: re.uri,
           c: r[Label] || r.uri },"<br>\n",
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
                   ]}, data ? "<br>" : " "]}}]}]}

  ViewGroup[LDP+'Resource'] = -> g,env {
    [(H.css '/css/page', true),
     (H.js '/js/pager', true),
     (H.js '/js/mu', true),
     ({_: :a, class: :up, href: '..', title: Pathname.new(env['REQUEST_PATH']).parent.basename, c: '&uarr;'} unless env['REQUEST_PATH'] == '/'),
     g.map{|u,r|
       ViewA[LDP+'Resource'][r,env]}]}

  ViewA[LDP+'Resource'] = -> u,e {
    label = -> r {(r.R.query_values.do{|q|q['offset']} || r).R.stripDoc.path.gsub('/',' ')}
    prev = u[Prev]
    nexd = u[Next]
    [Prev,Next,Type].map{|p|u.delete p}
    [prev.do{|p|
       {_: :a, rel: :prev, href: p.uri, c: ['↩ ', label[p]], title: '↩ previous page'}},
     nexd.do{|n|
       {_: :a, rel: :next, href: n.uri, c: [label[n], ' →'], title: '→ next page'}},
     ViewA[Resource][u,e]]}

  Tabulator = -> r,e {
    src = '//linkeddata.github.io/tabulator/'
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.js  '/js/tabr'),
     (H.css src + 'tabbedtab'),
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  ViewGroup[Container] = ViewGroup[Directory] = -> d,env {
    mtime = Stat+'mtime'
    env.q['sort'] ||= mtime
    sort = env.q['sort'].expand
    sortType = [mtime,Size].member?(sort) ? :to_i : :to_s
    sortLabel = sort.shorten.split(':')[-1] + ' ↨'
    s_ = case sort # next sort-predicate
         when Size
           'dc:date'
         when Date
           'dc:title'
         when Stat+'mtime'
           'dc:title'
         else
           'stat:size'
         end
    sortQ  = env.q.merge({'sort' => s_}).qs # querystring w/ next sort-order

    [{_: :a, class: :sort, c: sortLabel, href: sortQ, title: s_},
     H.css('/css/container',true),
     d.map{|u,r|
       ViewA[Container][r,env]}]}

  ViewGroup[Stat+'File'] = -> g,e {
    e.q['sort'] ||= Size
    sort = e.q['sort'].expand == Size ? Size : Stat+'mtime'
    {_: :table, style: 'float: right', c: g.values.sort_by{|i|i[sort][0]}.reverse.map{|r|
       {_: :tr, c: [{_: :td, c: r[Size]},
                    {_: :td, c: Time.at(r[Stat+'mtime'][0]).iso8601},
                    {_: :td, c: r.R.href},
                   ]}}}}

  def triplrAudio &f
    uri = '#'  + URI.escape(path)
    yield uri, Type, R[Sound]
    yield uri, Title, basename
  end
   
  ViewGroup[Sound] = -> g,e {
    [{_: :audio, id: :audio, style: 'width:100%', controls: true}, H.js('/js/audio'),
     ViewA[Container][{'uri' => '#sounds', LDP+'contains' => g.values },e]]}


end
