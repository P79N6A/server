# coding: utf-8
watch __FILE__
class R

  POST[SIOC+'Forum'] = -> d,e { # POSTing to Forum - create thread and OP (original post) in thread
    puts "forum post"
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
    editing = e.q.has_key?('new') || e.q.has_key?('edit')
    {class: :forum,
     c: [{_: :a, class: :title, href: r.uri.t + '?set=first-page', c: r[Title]},' ',
         {_: :span, class: :desc, c: r[Content]},
         ({_: :a, class: :edit, href: r.uri + '?edit', c: '✑'} if e.signedIn && !editing),
         ({_: :a, class: :new, href: r.uri + '?new', c: "+ post"} if e.signedIn && !editing)]}}

end
