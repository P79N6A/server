class R

  View['audio'] = ->d,e {
    [(H.once e, :audio,
      (H.js '/js/audio'), (H.css '/css/audio'),
      (H.once e, :mu, (H.js '/js/mu')),
      {id: :rand, c: :rnd}, {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true},
      {id: :jump, c: '&rarr;'}, {_: :iframe, id: :infoPane}),
     d.map{|u,_|{_: :a, class: :track, href: URI.escape(u), c: u.split(/\//)[-1].sub(/\.(flac|mp3|wav)$/,'')}}]}

  %w{aif wav mpeg mp4}.map{|a|View[MIMEtype+'audio/'+a]=View['audio']}
end
