# -*- coding: utf-8 -*-
watch __FILE__
class R

  fn '/thread/GET',-> e, r {
    m = {}
    R[MessagePath[e.stripDoc.basename]].walk SIOC+'reply_of', m
    return F[404][e,r] if m.empty?

    v = r.q['view'] ||= "timegraph"
    r['ETag'] = [(F['view/'+v] && v), m.keys.sort, r.format].h

    e.condResponse r.format, ->{e.render r.format, m, r}}
  
  fn 'view/threads',->d,env{
    posts = d.resourcesOfType SIOC+'Post'
    threads = posts.group_by{|r| # group by Title
       [*r[Title]][0].do{|t|t.sub(/^[rR][eE][^A-Za-z]./,'')}}

    [F['view/'+HTTP+'Response'][{'#' => d['#']},env],'<br clear=all>',
     (H.css '/css/threads'),{_: :style, c: "body {background-color: ##{rand(2).even? ? 'fff' : '000'}}"},
     '<table>',
     threads.group_by{|r,k| # group by recipient
       k[0].do{|k| k[To].do{|o|o.head.uri}}}.
     map{|group,threads| c = R.cs
       ['<tr><td class=subject>',
        threads.map{|title,msgs| # thread
          [{_: :a, property: Title, :class => 'thread', style: "border-color:#{c}", href: '/thread/'+msgs[0].R.base,
             c: title.to_s.gsub(/[<>]/,'_').gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>')},

           (msgs.size > 1 && # more than one author
            ['<br>', msgs.map{|s| # show authors
                {_: :a, property: Creator, href: '/thread/'+s.R.base+'#'+s.uri, :class => 'sender', style: 'background-color:'+c,
                 c: s[Creator].do{|c|c[0].uri.split('#')[1].split('@')[0]}}}]),'<br clear=all>']},'</td>',

        ({_: :td, class: :group, property: To,
          c: {_: :a, :class => :to, style: 'background-color:'+c, c: group.abbrURI, href: group}} if group),
        '</tr>']},'</table>',

     {_: :a, id: :down, href: env['REQUEST_PATH'] + env.q.merge({'view'=>''}).qs, c: '↓'}]}

end
