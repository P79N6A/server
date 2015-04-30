# coding: utf-8
#watch __FILE__
class R

  POST[Forum] = -> thread, forum, env {
    thread['uri'] = forum.uri + Time.now.iso8601[0..10].gsub(/[-T]/,'/') + thread[Title].slugify + '/'
    thread[SIOC+'reply_to'] = R[thread.uri + '?new#reply']
  }

  POST[SIOC+'Thread'] = -> post, thread, env {
    post['uri'] = thread.uri + time.gsub(/[-+:T]/, '')
    post[SIOC+'reply_to'] = R[thread.uri + '?new#reply']
  }

end
