# coding: utf-8
watch __FILE__
class R

  POST[SIOC+'Forum'] = -> d,e { # POSTing to Forum - create thread and OP (original post) in thread
    
  }

  Abstract[SIOCt+'BoardPost'] = -> graph, g, e {
    g.values.map{|p|
      p[SIOC+'reply_to'] = R[p.R.dirname + '?new']
    }
  }

  ViewGroup[SIOC+'Forum'] = -> g,e {
    [H.css('/css/forum'),
     g.values.map{|r|ViewA[SIOC+'Forum'][r,e]}]}

  ViewA[SIOC+'Forum'] = -> r,e {
    {class: :forum,
     c: [{_: :a, class: :title, href: r.uri.t + '?set=first-page', c: r[Title]},' ',
         {_: :span, class: :desc, c: r[Content]},
         ({_: :a, class: :edit, href: r.uri + '?edit', c: '✑'} if e.signedIn),
         ({_: :a, class: :new, href: r.uri + '?new', c: "+ post"} if e.signedIn)]}}

end
