# coding: utf-8
#watch __FILE__
class R

  # POSTable container -> contained types
  Containers = {
    Wiki => SIOCt+'WikiArticle',
    Forum            => SIOC+'Thread',
    SIOC+'Thread'    => SIOCt+'BoardPost',
   SIOCt+'BoardPost' => SIOCt+'BoardPost',
  }

  Filter[Container] = -> g,e { # summarize a container
    groups = {}
    g.map{|u,r|
      r.types.map{|type| # RDF types
        if v = Abstract[type] # summarizer
          groups[v] ||= {} # type-group
          groups[v][u] = r # resource -> group
        end}}
    groups.map{|fn,gr|fn[g,gr,e]}} # summarize

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
     {class: :containers,
      c: d.resources(env).map{|r|
        [ViewA[Container][r,env,d], {_: :p, class: :space}]}}]}

  GET['/tabulator'] = -> r,e {[200, {'Content-Type' => 'text/html'},[Render['text/html'][{}, e, Tabulator]]]}

  Tabulator = -> g,e {
    src = e.scheme + '://linkeddata.github.io/tabulator/'
    uri = e.scheme + ':' + e.R.path.sub(/^\/tabulator/,'/')
    [(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),
     (H.js  src + 'js/mashup/mashlib'),
     (H.css src + 'tabbedtab'),
     {_: :script, c: "
document.addEventListener('DOMContentLoaded', function(){
    var kb = tabulator.kb;
    var subject = kb.sym('#{uri}');
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
}, false);
"},
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  def triplrAudio &f
    yield uri, Type, R[Sound]
    yield uri, Title, bare
    yield uri, Size, size
    yield uri, Date, mtime
  end

  Abstract[Sound] = -> graph, g, e { # add player and playlist resources
    graph['#snd'] = {'uri' => '#snd', Type => R[Container],
                  LDP+'contains' => g.values.map{|s| graph.delete s.uri # original resource
                    s.update({'uri' => '#'+URI.escape(s.R.path)})}} # localized playlist-entry
    graph['#audio'] = {Type => R[Sound+'Player']} # player
    graph[e.uri].do{|c|c.delete(LDP+'contains')}} # original container

  ViewGroup[Sound+'Player'] = -> g,e {
    [{id: :audio, _: :audio, autoplay: :true, style: 'width:100%', controls: true}, {_: :a, id: :rand, href: '#rand', c: 'R'}, H.js('/js/audio'), {_: :style, c: "#snd {max-height: 24em; overflow:scroll}
#rand {color: #fff; background-color: brown; text-decoration: none; font-weight: bold; font-size: 3em; padding: .3em; border-radius: .1em}"}]}

end
