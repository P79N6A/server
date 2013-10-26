class E

  AudioInfo = %w{Album-Movie-Show_title Lead_performers-Soloists Title-songname-content_description}.map{|a|Audio+a}.concat [Stat+'mtime',Stat+'size']

  def audioNodes;take.select &:audioNode end;def audioNode;true if ext.match /(aif|wav|flac|mp3|m4a|aac|ogg)/i end
  def videoNodes;take.select &:videoNode end;def videoNode;true if ext.match /(avi|flv|mkv|mpg|mp4|wmv)/i end

  fn 'set/audio',->d,e,m{d.audioNodes}
  fn 'set/video',->d,e,m{d.videoNodes}

  fn 'view/audio',->d,e{
    i = F['view/audio/item']
    Fn 'view/audio/base',d,e,->{
      d.sort_by{|_,r|r[Stat+'mtime'][0].to_s}.
      reverse.map{|_,r|i.(r,e)}}}

  fn 'view/audio/base',->d,e,c=nil{
    [(H.once e,:mu,(H.js '/js/mu')),
     (H.once e,:audio,(H.js '/js/audio'),(H.css '/css/audio'),(H.css '/css/table'),
      {_: :span, id: :rand,r: :true,c: :r},{_: :span, id: :jump,c: '&rarr;'},
      {_: e.q.has_key?('video') ? :video : :audio, id: :player, controls: true}),
     {_: :table, class: :playlist, c: c.()}]}

  fn 'view/audio/item',->m,e{
    {_: :tr,
      c: [{_: :td, c: {_: :a, class: :entry, href: '#'+m.uri.gsub('%','%25').gsub('#','%23'), c: m.E.bare}},
          AudioInfo.map{|k|{_: :td, c: m[k].html}}]}}

end
