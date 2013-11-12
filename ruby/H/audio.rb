watch __FILE__
class E

  fn 'set/audio',->d,e,m{d.take.select{|e|e.ext.match AudioFiles}}
  fn 'set/video',->d,e,m{d.take.select{|e|e.ext.match VideoFiles}}

  AudioInfo = {}
  %w{Album-Movie-Show_title Lead_performers-Soloists Title-songname-content_description}.map{|a|Audio + a}.concat(['uri',Stat+'mtime', Stat+'size']).map{|p|
    AudioInfo[p] = true}

  fn 'view/audio',->d,e{

    # trim rare ID3-tags so table is reasonably-sized
    d.values.map{|r| r.delete_if{|p,o| !AudioInfo[p]}}

    [(H.once e, :mu, (H.js '/js/mu')),
     (H.once e, :audio, (H.js '/js/audio'), %w{audio table}.map{|c|(H.css '/css/'+c)},
      {id: :rand, c: :r},
      {id: :jump, c: '&rarr;'},
      {id: :info},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true}),'<br>',
     F['view/table'][d,e]]}  

end
