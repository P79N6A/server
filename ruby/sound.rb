class R

  def triplrAudio &f
    yield uri, Type, R[Sound]
    yield uri, Title, bare
    yield uri, Size, size
    yield uri, Date, mtime
  end

  Abstract[Sound] = -> graph, g, e { # put sounds in playlist container, add player resource
    graph['#snd'] = {'uri' => '#snd', Type => R[Container],
                  LDP+'contains' => g.values.map{|s| graph.delete s.uri
                    s.update({'uri' => '#'+URI.escape(s.R.path)})}} # playlist-entry
    graph['#audio'] = {Type => R[Sound+'Player']}} # player

  ViewGroup[Sound+'Player'] = -> g,e {
    [H.js('/js/audio'),
     {_: :audio, id: :audio, controls: true}]}

  def triplrImage &f
    yield uri, Type, R[Image]
  end

end
