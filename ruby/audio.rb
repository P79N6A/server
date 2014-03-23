class R

  VideoFile = /(avi|flv|mkv|mpg|mp4|wmv)$/i
  AudioFile = /(aif|wav|flac|mp3|m4a|aac|ogg)$/i

  fn 'fileset/audio',->d,e,m{
    e['view'] = 'audio'
    d.take.select{|e|e.ext.match AudioFile}}

  fn 'fileset/video',->d,e,m{
    e['view'] = 'audio'
    e['video'] = true
    d.take.select{|e|e.ext.match VideoFile}}

  # table of audio-resource properties
  AudioK = {}
  %w{Album-Movie-Show_title Lead_performers-Soloists Title-songname-content_description}.map{|a|Audio + a}.
    concat(['uri', Stat+'mtime', Stat+'size']).
    map{|p|AudioK[p] = true}

  fn 'view/audio',->d,e{ d = d.dup

    # skip non-audio files
    d.delete_if{|p,o|
      (p.respond_to? :match) &&
      (!p.match AudioFile)}

    # select data-fields
    d.values.map{|r|
      r.class==Hash &&
      r.delete_if{|p,o|!AudioK[p]}}

    [(H.once e, :mu, (H.js '/js/mu')),(H.once e, :audio,(H.js '/js/audio'),(H.css '/css/audio'),
      {id: :rand, c: :r}, {id: :jump, c: '&rarr;'}, {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true}), '<br>',
     F['view/table'][d,e]]}

end
