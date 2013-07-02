#watch __FILE__
class E

  F["?"]||={}; F["?"].update({'af'=>{'graph' => 'audioFind','view' => 'audioplayer'},
                               'a'=>{'set' => 'audio','view' => 'audioplayer'},
                               'v'=>{'set' => 'video','view' => 'audioplayer','video'=>true}})

  def audioNodes;take.select &:audioNode end;def audioNode;true if ext.match /(aif|wav|flac|mp3|m4a|aac|ogg)/i end
  def videoNodes;take.select &:videoNode end;def videoNode;true if ext.match /(avi|flv|mkv|mpg|mp4|wmv)/i end

  fn 'set/audio',->d,e,m{d.audioNodes}
  fn 'set/video',->d,e,m{d.videoNodes}

  fn 'graph/audioFind',->e,q,m{
    t=q['day'] && q['day'].match(/^\d+$/) && '-ctime -'+q['day']
    s=q['size'] && q['size'].match(/^\d+$/) && '-size +'+q['size']+'M'
    r=(q['find'] ? '.*'+q['find'].gsub(/[^a-zA-Z0-9\.\ ]+/,'.*') : '') + '.*.\(aif\|flac\|m4a\|mp3\|aac\|ogg\|wav\)'
    `find #{e.sh} #{t} #{s} -iregex "#{r}"`.lines.map{|p|p[BaseLen..-1].unpath.do{|a|m[a.uri]=a}}}

  fn 'view/audioplayer/item',->m,e{
    {_: :a,class: :entry, href: '#'+m.uri.gsub('%','%25').gsub('#','%23'),
      c: m.E.bare+" \n"}}

  fn 'view/audioplayer/base',->d,e,c=nil{
    [{_: :span, id: :jump,c: '&#x10c2;&nbsp;&nbsp;&nbsp;'},{_: :span, id: :rand,r: :true,c: :r},
     (H.once e,:mu,(H.js '/js/mu')),(H.js '/js/audio'),H.css('/css/audio'),H.css('/css/table'),
     {_: e.q.has_key?('video') ? :video : :audio, id: :player, controls: true},
     {id: :data},
     {id: :playlist,
       c: {:class => :playlistItems,c: c.()}}]}
  
  fn 'view/audioplayer',->d,e{i=F['view/audioplayer/item']
    Fn 'view/audioplayer/base',d,e,->{
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
