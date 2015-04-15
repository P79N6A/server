# coding: utf-8
#watch __FILE__
class R

  POST[Forum] = -> thread, forum, env { # default handler creates thread, add OP here
    time = Time.now.iso8601             # and mint a custom URI for the thread..
    title = thread[Title]
    thread['uri'] = forum.uri + time[0..10].gsub(/[-T]/,'/') + title.slugify + '/'
    postURI = thread.uri + time.gsub(/[-+:T]/, '') + '/'
    op = {
      'uri' => postURI,
      Creator => env.user,
      Type => R[SIOCt+'BoardPost'],
      Title => title,
      Content => (thread.delete Content),
      WikiText => (thread.delete WikiText),
      SIOC+'has_discussion' => thread.R,
      SIOC+'has_container' => thread.R,
      SIOC+'reply_to' => R[postURI + '?new']}
    postURI.R.writeResource op }

  # post to a Thread
  POST[SIOC+'Thread'] = -> post, thread, env {
    #
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
  ViewGroup[SIOC+'Thread'] = ViewGroup[Resource]

end
