# coding: utf-8
#watch __FILE__
class R

  POST[Forum] = -> thread, forum, env {
    # default handler creates a Thread due to container->contained mapping
    # but we'll give it a custom URI..
    thread['uri'] = forum.uri + Time.now.iso8601[0..10].gsub(/[-T]/,'/') + thread[Title].slugify + '/'
    # we also want an "original post" in the thread, so POST it too
  }

  # post to a Thread
  POST[SIOC+'Thread'] = -> post, thread, env {
    post['uri'] = thread.uri + time.gsub(/[-+:T]/, '')
  }

  # post to a Post (reply)
  POST[SIOC+'BoardPost'] = -> reply, post, env {
    thread = post[SIOC+'has_discussion'].R
    postURI = thread.uri + Time.now.iso8601.gsub(/[-+:T]/, '') + '/'
    reply.update({ 'uri' => postURI,
                   Creator => env.user,
                   Type => R[SIOCt+'BoardPost'],
                   SIOC+'has_parent' => post.R,
                   SIOC+'has_discussion' => thread.R,
                   SIOC+'has_container' => thread.R,
                   SIOC+'reply_to' => R[postURI + '?new']
                 })}

  ViewGroup[Forum] = ViewGroup[Resource]
  ViewGroup[SIOC+'Thread'] = TabularView

end
