# coding: utf-8
#watch __FILE__
class R

  ViewA[Resource] = -> r,e {r.html}

  ViewGroup[Resource] = -> g,e {
    [H.css('/css/html',true),
     g.resources(e).reverse.map(&:html)]}

  ViewA[Container] = ViewA[Directory] = -> r, e, graph = nil {
    re = r.R
    uri = re.uri
    e[:seen] ||= {}
    unless e[:seen][uri]
      e[:seen][uri] = true
      graph ||= {}
      path = (re.path||'').t
      group = e.q['group']
      sort = (e.q['sort']||'uri').expand
      color = e[:color][re.path||e.R.path] ||= R.cs
      {class: :container, id: re.fragment,
       c: [{_: :a, class: :uri, href: uri, style: "background-color: #{color}",c: r[Label] || re.fragment || re.basename },"<br>\n",
           r[LDP+'contains'].do{|c|
             sizes = c.map{|r|r[Size] if r.class == Hash}.flatten.compact
             maxSize = sizes.max
             sized = !sizes.empty? && maxSize > 1
             width = maxSize.to_s.size
             c.sortRDF(e).send((sized||sort==Date) ? :reverse : :id).map{|r|
               data = r.class == Hash
               if child = graph[r.uri]
                 ViewA[Container][child,e,graph]
               else
                 [{_: :a, href: r.R.uri, class: :member,
                   c: [(if data && sized && r[Size]
                        s = r[Size].justArray[0]
                        [{_: :span, class: :size, c: (s > 1 ? "%#{width}d" % s : ' '*width).gsub(' ','&nbsp;')}, ' ']
                        end),
                       ([r[Date],' '] if data && sort==Date),
                       data && (r[Title] || r[Label]) || r.R.abbr[0..64]
                      ]}, data ? "<br>" : " "]
               end
             }} ||
           ({class: :down, c: {_: :a, href: uri, style: "color: #{color}", c: '&darr;' }} if uri != e.R.uri && r[Size].justArray[0].to_i>0)]}
    end}

  ViewGroup[Container] = ViewGroup[Directory] = -> d,env {
    path = env.R.path
    sort = (env.q['sort']||Size).expand
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
    env[:color] ||= {path => '#222'}
    [H.css('/css/container',true),
     {_: :a, class: :sort, href: env.q.merge({'sort' => s_}).qs, c: '↨' + sort.shorten.split(':')[-1]},
     if env[:ls]
       TabularView[d,env]
     else
     d.resources(env).group_by{|r|r.R.path||path}.map{|group,resources|
        resources.map{|r|
          [ViewA[Container][r,env,d], {_: :p, class: :space}]}}
     end
    ]}

  ViewGroup[LDP+'Resource'] = -> g,env {
    [H.css('/css/page', true),
     H.js('/js/pager', true),
    ({_: :a, class: :up, href: Pathname.new(env['REQUEST_PATH']).parent, c: '&uarr;'} unless env['REQUEST_PATH'] == '/'),
    (if env[:new]
     if !env.q.has_key?('type')
       ViewA['#newType'][g,env]
     else
       ViewA['#editable'][g,env]
     end
     end),
     g.map{|u,r|ViewA[LDP+'Resource'][r,env]},
     {_: :a, class: :cube, href: '??', c: {_: :img, src: '/css/misc/cube.png'}}]}

  ViewA[LDP+'Resource'] = -> u,e {
    label = -> r {(r.R.query_values.do{|q|q['offset']} || r).R.stripDoc.path.gsub('/',' ')}
    prev = u[Prev]
    nexd = u[Next]
    [Prev,Next,Type].map{|p|u.delete p}
    [prev.do{|p|
       {_: :a, rel: :prev, href: p.uri, c: ['↩ ', label[p]], title: '↩ previous page'}},
     nexd.do{|n|
       {_: :a, rel: :next, href: n.uri, c: [label[n], ' →'], title: 'next page →'}},
    (ViewA[Resource][u,e] unless u.keys.size==1)]}

  Tabulator = -> r,e {
    src = '//linkeddata.github.io/tabulator/'
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.js  '/js/tabr'),
     (H.css src + 'tabbedtab'),
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  ViewGroup[Content+'Resource'] = -> d,env {
    d.values.map{|r|r[Content]}}

  def triplrAudio &f
    yield uri, Type, R[Sound]
    yield uri, Title, bare
    yield uri, Size, size
    yield uri, Date, mtime
  end

  Abstract[Sound] = -> graph, g, e {
    c = '#sounds'
    graph[c] = {'uri' => c, Type => R[Container],
                LDP+'contains' => g.values.map{|s|
                  graph.delete s.uri
                  s.update({'uri' => '#'+URI.escape(s.R.path)})}}
    graph['#audio'] = {Type => R[Sound+'Player']}
    graph[e.uri].do{|c|c.delete(LDP+'contains')}
  }

  ViewGroup[Sound+'Player'] = -> g,e {
    [{id: :audio, _: :audio, autoplay: :true, style: 'width:100%', controls: true}, H.js('/js/audio')]}

end

class Hash
  def html
    if keys.size == 1 && has_key?('uri')
      r = self.R
      H({_: :a, href: uri, c: r.fragment || r.basename, class: :id})
    else
      H({_: :table,
         class: :html,
         id: uri.do{|u|u.R.fragment||u.R.uri}||'#',
         c: map{|k,v|
           {_: :tr, property: k,
            c: case k
               when 'uri'
                 {_: :td, class: :uri, colspan: 2, c: {_: :a, href: v,
                      c: (self[R::Label] || self[R::Title] || v.R.abbr).justArray[0].to_s.noHTML}}
               when R::Content
                 {_: :td, class: :val, colspan: 2, c: v}
               else
                 [{_: :td, c: {_: :a, href: k, c: k.to_s.R.abbr}, class: :key},
                  {_: :td, c: v.html, class: :val}]
               end}}})
    end
  end
end
