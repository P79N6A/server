# coding: utf-8
watch __FILE__
class R

  # post to a Forum creates a thread and its first post
  POST[SIOC+'Forum'] = -> thread, forum { # URI-less thread from base-handler
    time = Time.now.iso8601
    title = thread[Title] # mint thread-URI
    thread['uri'] = forum.uri + time[0..10].gsub(/[-T]/,'/') + title.slugify + '/'
    postURI = thread.uri + time.gsub(/[-+:T]/, '')
    op = {# "original post" in thread
      'uri' => postURI,
      Type => R[SIOCt+'BoardPost'],
      Title => title,
      Content => (thread.delete Content),
      SIOC+'has_discussion' => thread.R,
      SIOC+'has_container' => thread.R,
      SIOC+'reply_to' => R[postURI + '?new']}
    R.writeResource op, true} # store OP

  # post to a Thread
  POST[SIOC+'Thread'] = -> post, thread {
    
  }

  # post to a Post (reply)
  POST[SIOC+'Post'] = -> reply, post {
    
  }
  

  ViewGroup[SIOC+'Forum'] = -> g,e {
    [H.css('/css/forum',true),
     g.values.map{|r|ViewA[SIOC+'Forum'][r,e]}]}

  ViewA[SIOC+'Forum'] = -> r,e {
    editing = e.q.has_key?('new') || e.q.has_key?('edit')
    editPtr = e.signedIn && !editing
    {class: :forum,
     c: [{_: :a, class: :title, href: r.uri.t + '?set=first-page', c: r[Title]},
         ({_: :a, class: :edit, href: r.uri + '?edit', c: '✑', title: 'edit forum-details'} if editPtr),'<br>',
         {_: :span, class: :desc, c: r[Content]},
         ({_: :a, class: :post, href: r.uri + '?new', c: "✑ post"} if editPtr)]}}

  ViewGroup[SIOC+'Thread'] = -> g,e {
    [H.css('/css/thread',true),
     g.values.map{|r|ViewA[SIOC+'Thread'][r,e]}]}

  ViewA[SIOC+'Thread']= -> r,e {
    forum = r[SIOC+'has_container'].justArray[0]
    {_: :h2,
     c: [({_: :a, class: :forum, href: forum.uri, c: forum.R.basename + '/'} if forum),
         {_: :a, class: :thread,href: r.uri, c: r[Title]}]}}

end
