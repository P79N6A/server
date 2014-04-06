watch __FILE__
class R

  VideoFile = /(avi|flv|mkv|mpg|mp4|wmv)$/i
  AudioFile = /(aif|wav|flac|mp3|m4a|aac|ogg)$/i

  View['audio'] = ->d,e {
    [(H.once e, :audio,(H.js '/js/audio'),(H.css '/css/audio'),(H.once e, :mu, (H.js '/js/mu')),
      {id: :rand, c: :r}, {id: :jump, c: '&rarr;'}, {id: :info, target: :_blank, _: :a},
      {_: e.q.has_key?('video') ? :video : :audio, id: :media, controls: true}),
     d.map{|u,_|u.href}]}

  %w{aif wav mpeg}.map{|a|View[MIMEtype+'audio/'+a]=View['audio']}
end
