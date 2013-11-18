class E

  fn 'set/audio',->d,e,m{d.take.select{|e|e.ext.match AudioFile}}
  fn 'set/video',->d,e,m{d.take.select{|e|e.ext.match VideoFile}}

  AudioK = {}
  %w{Album-Movie-Show_title Lead_performers-Soloists Title-songname-content_description}.map{|a|Audio + a}.concat(['uri',Stat+'mtime', Stat+'size']).map{|p|AudioK[p] = true}

  fn 'view/audio',->d,e{

#    d.delete_if{|p,o| !p.match AudioFile }
    d.values.map{|r| r.delete_if{|p,o| !AudioK[p] }}

    [(H.once e, :mu, (H.js '/js/mu')),
     (H.once e, :audio, (H.js '/js/audio'), (H.css '/css/audio'),
      {id: :rand,c: :r}, {id: :jump,c: '&rarr;'}, {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true}),'<br>',
     F['view/table'][d,e]]}

end
