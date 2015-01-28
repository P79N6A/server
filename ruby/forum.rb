# coding: utf-8
watch __FILE__
class R

  POST[SIOC+'Forum'] = -> thread, forum {
    time = Time.now.iso8601
    title = thread[Title]
    thread['uri'] = forum.uri + time[0..9].gsub(/[-T]/,'/') + title.slugify + '/'
    op = {
      'uri' => thread.uri + time.gsub(/[-+:T]/, ''),
      Type => R[SIOCt+'BoardPost'],
      Title => title,
      Content => thread[Content],
      SIOC+'has_container' => thread.R,
    }
    thread.delete Content
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
    editPtr = e.signedIn && !editing
    {class: :forum,
     c: [{_: :a, class: :title, href: r.uri.t + '?set=first-page', c: r[Title]},
         ({_: :a, class: :edit, href: r.uri + '?edit', c: '✑'} if editPtr),
         {_: :span, class: :desc, c: r[Content]},
         ({_: :a, class: :post, href: r.uri + '?new', c: "✑ post"} if editPtr)]}}

end
