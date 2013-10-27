watch __FILE__
class E

  fn 'set/audio',->d,e,m{d.take.select{|e|e.ext.match /(aif|wav|flac|mp3|m4a|aac|ogg)/i}}
  fn 'set/video',->d,e,m{d.take.select{|e|e.ext.match /(avi|flv|mkv|mpg|mp4|wmv)/i}}

  fn 'view/audio',->d,e{
    Fn 'view/audio/base',d,e,->{
      d.sort_by{|_,r|r[Stat+'mtime'][0].to_s}.
      reverse.map{|_,r|F['view/audio/item'][r,e]}}}

  fn 'view/audio/base',->d,e,c=nil{
    [(H.once e,:mu, (H.js '/js/mu')),
     (H.once e,:audio, (H.js '/js/audio'), %w{audio table}.map{|c|(H.css '/css/'+c)},
      {id: :rand, c: :r}, {id: :jump, c: '&rarr;'}, {id: :info},
      {_: e.q.has_key?('video') ? :video : :audio, id: :player, controls: true}),'<br clear=all>',
     {class: :table, c: c.()}]}

  fn 'view/audio/item',->m,e{
    {class: :tr, c: [{class: :td, c: {_: :a, href: '#'+m.uri.gsub('%','%25').gsub('#','%23'), c: m.E.bare}},
          %w{Album-Movie-Show_title Lead_performers-Soloists Title-songname-content_description}.map{|a|Audio+a}.
          concat([Stat+'mtime',Stat+'size']).map{|k|{class: :td, c: m[k].html}}]}}

end
