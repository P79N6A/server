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

  ViewA[Container] = -> r, e, sort, direction {
    re = r.R
    uri = re.uri
    path = (re.path||'').t
    group = e.q['group']
    {class: :container,
     c: r[LDP+'contains'].do{|c|
       sizes = c.map{|r|r[Size] if r.class == Hash}.flatten.compact
       maxSize = sizes.max
       sized = !sizes.empty? && maxSize > 1
       width = maxSize.to_s.size
       c.sortRDF(e).send(direction).map{|r|
         data = r.class == Hash
         [{_: :a, href: r.R.uri, class: :member,
           c: [(if data && sized && r[Size]
                s = r[Size].justArray[0]
                [{_: :span, class: :size, c: (s > 1 ? "%#{width}d" % s : ' '*width).gsub(' ','&nbsp;')}, ' ']
                end),
               ([r[Date].justArray[0].to_s,' '] if data && sort==Date),
               data && CGI.escapeHTML((r[Title] || r[Label] || r.R.fragment || r.R.basename).justArray[0].to_s) || r.R.abbr[0..64]
              ]}, data ? "<br>" : " "]}}}}

  Icons = {
    Container => :dir,
    Directory => :warp,
    FOAF+'Person' => :person,
    GraphDoc => :graph,
    Resource => :graph,
    Image => :img,
    SIOC+'Thread' => :thread,
    SIOC+'Usergroup' => :group,
    Stat+'File' => :file,
    '#editable' => :scissors,
  }

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
