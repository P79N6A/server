class R

  def triplrAudio &f
    yield uri, Type, R[Sound]
    yield uri, Title, bare
    yield uri, Size, size
    yield uri, Date, mtime
  end

  Abstract[Sound] = -> graph, g, e { # create player and playlist resources
    graph['#snd'] = {'uri' => '#snd', Type => R[Container],
                  LDP+'contains' => g.values.map{|s| graph.delete s.uri # original entry
                    s.update({'uri' => '#'+URI.escape(s.R.path)})}} # localized playlist-entry
    graph['#audio'] = {Type => R[Sound+'Player']} # player
    graph[e.uri].do{|c|c.delete(LDP+'contains')}} # original container

  ViewGroup[Sound+'Player'] = -> g,e {
    [{id: :audio, _: :audio, autoplay: :true, style: 'width:100%', controls: true}, {_: :a, id: :rand, href: '#rand', c: 'R'}, H.js('/js/audio'), {_: :style, c: "#snd {max-height: 24em; overflow:scroll}
#rand {color: #fff; background-color: brown; text-decoration: none; font-weight: bold; font-size: 3em; padding: .3em; border-radius: .1em}"}]}
  def triplrImage &f
    yield uri, Type, R[Image]
  end

end
