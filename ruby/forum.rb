# coding: utf-8
#watch __FILE__
class R

  POST[Forum] = -> thread, forum, env { # base handler creates thread (Container->contained mapping)
                                        # we also want an "original post" in the thread. create it here
    time = Time.now.iso8601             # also we mint a bespoke URI for the thread
    title = thread[Title]
    thread['uri'] = forum.uri + time[0..10].gsub(/[-T]/,'/') + title.slugify + '/'
    postURI = thread.uri + time.gsub(/[-+:T]/, '')
    op = {
      'uri' => postURI,
      Creator => env.user,
      Type => R[SIOCt+'BoardPost'],
      Title => title,
      Content => (thread.delete Content),
      WikiText => (thread.delete WikiText),
      SIOC+'has_discussion' => thread.R,
      SIOC+'has_container' => thread.R,
      SIOC+'reply_to' => R[thread.uri + '?new']}

    postURI.R.writeResource op } # store OP

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
