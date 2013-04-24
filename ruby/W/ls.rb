#watch __FILE__
class E

  # directory -> resourceSet
  fn 'set/ls',->d,e,m{d.c}

  # filesystem metadata only
  fn 'graph/ls',->d,e,m{d.c.map{|c|c.fromStream m,:tripleSourceNode,false}}

  fn 'set/subtree',->d,r,m{
    c =(r['c'].do{|c|c.to_i + 1} || 3).max(100) # one extra for start of next-page
    o = r['d'] =~ /^a/ ? :asc : :desc           # direction
    ('/'.E.take c, o, d.uri).do{|s|             # take subtree
      desc, asc = o == :desc ?                  # orient pagination hints
      [s.pop, s[0]] : [s[0], s.pop]
      m['prev'] = {'uri' => 'prev', 'url' => desc.url,'d' => 'desc'}
      m['next'] = {'uri' => 'next', 'url' => asc.url, 'd' => 'asc'}
      s }}

  # minimal view :: 
  fn 'view/dir',->i,e{
    a = -> i { e = i.E
      e.uri.match(/(gif|jpe?g|png)$/i) ?
      {_: :a, href: e.uri, c: {_: :img, src: i.uri+'?233x233'}} : [e.html,' ']}
    [(H.css '/css/ls'),
     i.map{|u,r| r['fs:child'] ? # directory?
       {class: :dir, style: "background-color: #{E.c}", # dir wrapper
         c: [{_: :a, href: r.uri, c: r.uri}, # dir
             r['fs:child'].map{|c|a[c]}]} :  # children
       a[r]}]}                               # item
  F['view/inode/directory']=F['view/dir']

  # tabular rendering
  fn 'view/ls',->i,e{
    [(H.css '/css/ls'),(Fn 'view/tab',i,e),(Fn 'view/find',i,e),
     {_: :a, class: :du, href: e['REQUEST_PATH'].t+'??=du', c: :du}]}

  fn 'req/guessFiles',->e,r{ g = {}
    Fn 'graph/ls', e, nil, g
    g.values.map{|e|e.E.base}.do{|b|
      s = b.size.to_f
      # email
      if b.grep(/^msg\./).size / s > 0.42
        [302, {Location: e.uri+'?set=ls&view=page&v=threads'},[]]
      # audio
      elsif b.grep(/(aif|wav|flac|mp3|m4a|aac|ogg)$/i).size / s > 0.8
        [302, {Location: e.uri+'?graph=ls&view=page&v=audioplayer'},[]]
      # images
      elsif b.grep(/(gif|jpe?g|png)$/i).size / s > 0.8
        [302, {Location: e.uri+'?graph=ls&view=page&v=th'},[]]
      # irc
      elsif b.grep(/\.log$/).size / s > 0.8
        [302, {Location: e.uri+'?set=ls&view=page&v=chat'},[]]
      # default
      else
        [302, {Location: e.uri+'?graph=ls&view=dir'},[]]
      end}}
     
end
