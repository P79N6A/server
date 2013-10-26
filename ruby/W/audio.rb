watch __FILE__
class E

  F["?"]||={}; F["?"].update({'a'=>{'set' => 'audio','view' => 'audio'},
                              'v'=>{'set' => 'video','view' => 'audio','video'=>true}})

  def audioNodes;take.select &:audioNode end;def audioNode;true if ext.match /(aif|wav|flac|mp3|m4a|aac|ogg)/i end
  def videoNodes;take.select &:videoNode end;def videoNode;true if ext.match /(avi|flv|mkv|mpg|mp4|wmv)/i end

  fn 'set/audio',->d,e,m{d.audioNodes}
  fn 'set/video',->d,e,m{d.videoNodes}

  fn 'set/findaudio',->e,q,m{
    F['set/find'][e,q,m,'\(aif\|flac\|m4a\|mp3\|aac\|ogg\|wav\)']}

  fn 'view/audio/item',->m,e{
    {_: :a,class: :entry, href: '#'+m.uri.gsub('%','%25').gsub('#','%23'),
      c: m.E.bare+" \n"}}

  fn 'view/audio/base',->d,e,c=nil{
    [(H.once e,:mu,(H.js '/js/mu')),
     (H.once e,:audio,
      {_: :span, id: :jump,c: '&#x10c2;&nbsp;&nbsp;&nbsp;'},
      {_: :span, id: :rand,r: :true,c: :r},
      {id: :data},
      (H.js '/js/audio'),
      (H.css '/css/audio'),
      (H.css '/css/table'),
      {_: e.q.has_key?('video') ? :video : :audio, id: :player, controls: true}),
     {id: :playlist,
       c: {:class => :playlistItems,c: c.()}}]}
  
  fn 'view/audio',->d,e{i=F['view/audio/item']
    Fn 'view/audio/base',d,e,->{
      d.group_by{|u,r|
        u.split('/')[0..-2].join '/'}.map{|b,g|
        [{_: :a, class: :directory, href: b, c: ['<br>',b,'<br>']},"\n",
         g.map{|r|i.(r[1],e)},"\n"]}}}

  def audioScan
    a('.png').e ||
      (e = ext; d = sh
       un = e.match /^(aif|wav)$/i # compressed?
       a = un ? d : d+'.wav' # analyze
       (case e
        when 'flac'
          `flac -d #{d} -o #{a}`
        when 'mp3'
          `lame --decode #{d} #{a}`
        when 'ogg'
          `oggdec #{d} -o #{a}`
        end) unless un
       `waveformgen #{a} #{d}.png -l`
       `sndfile-spectrogram --no-border #{a} 1280 800 #{d}.spec.png`
       `rm #{a}` unless un) end

end
