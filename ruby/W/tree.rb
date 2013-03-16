class E

  fn 'view/tree',->d,e{ t={}; c={}
    d.map{|u,r| l=t
      u.split(/[\/#]/).
      map{|s|
        l=(l[s] ||= {})}
      l['#']={u => r}}
    r=->t,d=0{
      t.except('#').map{|k,t_|
        {_: :div, class: :branch,style: 'background-color:'+(c[d]||=E.c),
         c: [t_['#'].do{|t|Fn 'view/'+e.q['treev'],t,e}||k,r.(t_,d+1)]}}}
  [(H.once e,'tree',(H.css '/css/tree')),r.(t)]}

  fn 'view/treeR',->d,e{ t={}; c={}
   d.map{|_,r| r.map{|p,o| l = t
     p.split(/[\/#]/).map{|s|l=(l[s]||={})}
          l['#']||=[]
          l['#'].push o}}
    r=->t,d=0{
      t.except('#').map{|k,t_|
        {_: :div, class: :branch,style: 'background-color:'+(c[d]||=E.c),
     c: ['<b>',k,'</b>',{class: :treeO,c: t_['#'].html},r.(t_,d+1)]}}}
  [(H.once e,'tree',(H.css '/css/tree')),r.(t)]}

end
