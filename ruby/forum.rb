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
    re = r.R.stripFrag
    title = r[Title][0]
    {class: :forum,
     c: [{_: :a, class: :title, href: re.uri.t + '?set=first-page', c: title},' ',
         {_: :span, class: :desc, c: r[Content]},'<br>',
      {_: :a, class: :new, href: re.uri.t + '?new', c: "+ post"}]}}

end
