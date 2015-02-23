# coding: utf-8
#watch __FILE__
class R

  Containers = { # container -> contained type
    Forum => SIOC+'Thread',
    SIOC+'Thread' => SIOCt+'BoardPost',
    SIOCt+'BoardPost' => SIOCt+'BoardPost',
    Wiki => SIOCt+'WikiArticle',
  }

  ViewA[Container] = -> r, e, graph = nil {
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
                       ([r[Date].justArray[0].to_s,' '] if data && sort==Date),
                       data && (r[Title] || r[Label]) || r.R.abbr[0..64]
                      ]}, data ? "<br>" : " "]
               end
             }} ||
           ({class: :down, c: {_: :a, href: uri, style: "color: #{color}", c: '&darr;' }} if uri != e.R.uri && r[Size].justArray[0].to_i>0)]}
    end}

  ViewGroup[Container] = -> d,env {
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
       {class: :containers,
        c: d.resources(env).group_by{|r|r.R.path||path}.map{|group,resources|
          resources.map{|r|
            [ViewA[Container][r,env,d], {_: :p, class: :space}]}}}
     end
    ]}

  Tabulator = -> r,e { # data-browser (and editor)
    src = '//linkeddata.github.io/tabulator/'
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.js  '/js/tabr'),
     (H.css src + 'tabbedtab'),
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  def triplrAudio &f
    yield uri, Type, R[Sound]
    yield uri, Title, bare
    yield uri, Size, size
    yield uri, Date, mtime
  end

  Abstract[Sound] = -> graph, g, e { # add player and playlist resources
    c = '#sounds' # playlist URI
    graph[c] = {'uri' => c, Type => R[Container], # playlist
                LDP+'contains' => g.values.map{|s|
                  graph.delete s.uri # hide non-playlist (duplicate) mention of this resource
                  s.update({'uri' => '#'+URI.escape(s.R.path)})}} # playlist entry
    graph['#audio'] = {Type => R[Sound+'Player']} # player
    graph[e.uri].do{|c|c.delete(LDP+'contains')}} # hide

  ViewGroup[Sound+'Player'] = -> g,e {
    [{id: :audio, _: :audio, autoplay: :true, style: 'width:100%', controls: true}, H.js('/js/audio')]}

end
