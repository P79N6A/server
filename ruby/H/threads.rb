watch __FILE__
class E
  
  fn 'protograph/thread',->d,_,g{
    d.walk SIOC+'reply_of',g
    F['docsID'][g]}
  
  fn 'view/threads',->d,env{

    # CSS
    [(H.css '/css/threads'),{_: :style, c: "body {background-color: ##{rand(2).even? ? 'fff' : '000'}}"},

     # predicate tafting
     ([{_: :a, class: :rangeP, href: '/@'+env.q['p']+'?set=indexP&view=page&v=linkPO&c=12', c: env.q['p'].do{|p|
           {'sioc:addressed_to' => 'to',
             Creator => 'from'}[p] || p
         }},'&nbsp;',
       {_: :a, class: :rangePO, href: E[env['uri']].url+'?set=indexPO&view=page&v=threads&c=32&p='+env.q['p'], c: env['uri']}
      ] if env.q['set']=='indexPO'),

     '<table>',

     # group posts by thread name
     d.values.select{|r| r[Type].do{|t| t.map(&:uri).member? SIOC+'Post'}
     }.group_by{|r|
       [*r[Title]][0].do{|t|t.sub(/^[rR][eE][^A-Za-z]./,'')}}.

     # group by recipient
     group_by{|r,k| k[0].do{|k|
         k[To].do{|o|o.head.uri}}}.map{|e|

       # rec-group
       c = E.c
       ['<tr><td class=subject>', e[1].map{|t|

          # link to thread
          [{_: :a, property: Title, :class => 'thread', style: "border-color:#{c}", href: t[1][0].url+'??=thread',
             c: t[0].to_s.gsub(/[<>]/,'_').gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>')},


           # link to individual post
           (t[1].size > 1 &&
            ['<br>', t[1].map{|s|

               # author name and RDFa
               [{_: :a, property: Creator, href: s.url+'??=thread#'+s.uri, :class => 'sender', style: 'background-color:'+c,
                  c: (s[SIOC+'name']||s[Creator]).do{|n|n[0]}
                },' ']}]),'<br>']},'</td>',

        # label & link to group
        {_: :td, class: :group, property: To,
          c: {_: :a, :class => :to, style: 'background-color:'+c, c: e[0] && e[0].split(/@/)[0],
            href: e[0] && e[0].E.url+'?set=indexPO&p=sioc:addressed_to&view=page&v=threads'}},

        '</tr>']},'</table>',

     # link to unabbreviated content of post-set
     {_: :a, id: :down, c: '&darr;',
       href: env['REQUEST_PATH'] + env.q.merge({'view'=>'page','views'=>'timegraph,mail','arc'=>'/parent','v'=>'multi','sort'=>'dc:date','reverse'=>true}).qs}]}

  F["?"] ||= {}
  F["?"].update({'thread' =>{
                    'graph'=>'thread',
                    'sort' => 'dc:date',
                    'reverse' => nil,
                    'view' => 'multi',
                    'views' => 'timegraph,mail',
                    'arc' => '/parent',
                    'label' => 'sioc:name'},
                  'ann' =>{
                    'view'=>'threads',
                    'set'=>'glob',
                    'matchP' => 'dc:title',
                    'match' => /[^a-zA-Z][Aa][Nn][nN]([oO][uU]|[^a-zA-Z])/}})

end
