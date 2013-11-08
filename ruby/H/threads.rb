class E

  F["?"] ||= {}
  F["?"].update({
   'thread' =>{'graph'=>'thread',
               'sort' => 'dc:date',
               'reverse' => nil,
               'view' => 'multi',
               'views' => 'timegraph,mail',
               'arc' => '/parent',
               'label' => 'sioc:name'},
      'ann' =>{'view'=>'threads',
               'matchP' => 'dc:title',
               'match' => /[^a-zA-Z][Aa][Nn][nN]([oO][uU]|[^a-zA-Z])/}})

    fn 'protograph/thread',->d,_,g{
    d.walk SIOC+'reply_of',g
    F['docsID'][g]}

  fn 'view/threads',->d,env{

    # occurrence-count statistics
    g = {}
    d.map{|_,m|
      m[To].do{|to|to.map{|t|
          g[t.uri]||=0
          g[t.uri]=g[t.uri].succ}}}

    # CSS
    [(H.css '/css/mail.threads'),{_: :style, c: "body {background-color: ##{rand(2).even? ? 'fff' : '000'}}"},

     # predicate tafting
     ([{_: :a, class: :rangeP, href: '/@'+env.q['p']+'?set=indexP&view=page&v=linkPO&c=12', c: env.q['p']},'&nbsp;',
       {_: :a, class: :current, href: '/m?y=day', c: ' '},'&nbsp;',
       {_: :a, class: :rangePO, href: E[env['uri']].url+'?set=indexPO&view=page&v=threads&c=32&p='+env.q['p'], c: env['uri']}
      ] if env.q['set']=='indexPO'),

     '<table>',

     # subgroup by title
     d.values.group_by{|r|
       [*r[Title]][0].do{|t|t.sub(/^[rR][eE][^A-Za-z]./,'')}}.

     # group by recipient
     group_by{|r,k|

       # show most-popular first
       k[0].do{|k|
         k[To].do{|o|o.sort_by{|t|g[t.uri]}.reverse.head.uri}}}.

     # display
     map{|e|
       # recipient-group color
       c = '#%06x' % rand(16777216)
       ['<tr><td class=subject>',
        
        # show most-popular groups first
        e[1].sort_by{|m|m[1].size}.reverse.map{|t|

          # link to thread
          [{_: :a, property: Title, :class => 'thread', style: "border-color:#{c}", href: t[1][0].url+'??=thread',
             c: t[0].to_s.gsub(/[<>]/,'_').gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>')},

           # link to individual post
           (t[1].size > 1 &&
            ['<br>', t[1].map{|s|

               # author name and RDFa
               [{_: :a, property: Creator, href: s.url+'??=thread#'+s.uri, :class => 'sender', style: 'background-color:'+c,
                  c: s[SIOC+'name'].do{|n|n[0].split(/\W/,2)[0]}
                },' ']}]),'<br>']},'</td>',

        # recipient group
        {_: :td, class: :group, property: To,
          c: {_: :a, :class => :to, style: 'background-color:'+c, c: e[0] && e[0].split(/@/)[0],
            href: e[0] && e[0].E.url+'?set=indexPO&p=sioc:addressed_to&view=page&v=threads'}},

        '</tr>']},'</table>',

     # link to unabbreviated content of post-set
     {_: :a, id: :down, c: '&darr;',
       href: env['REQUEST_PATH'] + env.q.merge({'view'=>'page','views'=>'timegraph,mail','arc'=>'/parent','v'=>'multi','sort'=>'dc:date','reverse'=>true}).qs}]}

end
