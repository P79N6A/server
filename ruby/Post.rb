class WebResource

  module HTML

    Markup[BlogPost] = Markup[Email] = -> post , env, flip='bw' {
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
       c: [{_: :a, class: :newspaper, href: cache||canonical},
           titles.map{|title|
             Markup[Title][title,env,canonical]},
           {_: :table,
            c: {_: :tr,
                c: [{_: :td, c: from.map{|f|Markup[Creator][f,env]}, class: :from},
                    {_: :td, c: '&rarr;'},
                    {_: :td, c: to.map{|f|Markup[Creator][f,env]}, class: :to}]}},
           (HTML.kv post, env, flip), # extra metadata in kv format
           (['<br>', Markup[Date][date]] if date)]}}

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
