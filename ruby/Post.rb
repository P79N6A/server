class WebResource

  module HTML
    Markup[Title] = -> title,env=nil,url=nil {
      title = CGI.escapeHTML title.to_s
      [if url
       {_: :a, class: :title, c: title, href: url, id: 'post'+rand.to_s.sha2}
      else
        {_: :h3, c: title}
      end,'<br>']}

    Markup[Creator] = -> c, env, urls=nil {
      if c.respond_to? :uri
        u = c.R
        name = u.fragment || u.basename.do{|b|b=='/' ? u.host : b} || u.host || 'user'
        color = env[:colors][name] ||= (HTML.colorizeBG name)
        {_: :a, class: :creator, style: color, href: urls.justArray[0] || c.uri, c: name}
      else
        CGI.escapeHTML (c||'')
      end}

    Markup[BlogPost] = Markup[Email] = -> post , env {
      # hidden fields in default view
      [:name, Type, Comments, Identifier, RSS+'comments', SIOC+'num_replies'].map{|attr|post.delete attr}
      # bind data
      canonical = post.delete('uri').justArray[0]
      cache = post.delete(Cache).justArray[0]
      titles = post.delete(Title).justArray.map(&:to_s).map(&:strip).uniq
      date = post.delete(Date).justArray[0]
      from = post.delete(From).justArray
        to = post.delete(To).justArray

      {class: :post,
       c: [{_: :a, class: :title, href: cache||canonical},
           titles.map{|title|
             Markup[Title][title,env,canonical]},
           (Markup[Date][date] if date),
           {_: :table,
            c: {_: :tr,
                c: [{_: :td, c: from.map{|f|Markup[Creator][f,env]}, class: :from},
                    {_: :td, c: '&rarr;'},
                    {_: :td, c: to.map{|f|Markup[Creator][f,env]}, class: :to}]}},'<br>',
           ((HTML.kv post, env) unless post.empty?)]}}

    # group by sender
    Group['from'] = -> graph { Group['from-to'][graph,Creator] }

    # group by recipient
    Group['to'] = -> graph { Group['from-to'][graph,To] }

    # group by sender or recipient
    Group['from-to'] = -> graph,predicate {
      users = {}
      graph.values.map{|msg|
        msg[predicate].justArray.map{|creator|
          c = creator.to_s
          users[c] ||= {name: c, Type => R[Container], Contains => {}}
          users[c][Contains][msg.uri] = msg }}
      users}

  end
end
