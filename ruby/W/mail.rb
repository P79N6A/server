#watch __FILE__
require_relative 'mailTmail'
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

  alias_method :triplrMail, :triplrTmail

  fn 'graphID/thread',->d,_,g{
    d.walk SIOC+'reply_of',g
    F['graphIDkeys'][g]}

  # overview of all messages in set
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

           # link to individual messages
           (t[1].size > 1 &&
            ['<br>', t[1].map{|s|

               # author name and RDFa
               [{_: :a, property: Creator, href: s.url+'??=thread#'+s.uri, :class => 'sender', style: 'background-color:'+c,
                  c: s[SIOC+'name'].do{|n|n[0].split(/\W/,2)[0]}
                },' ']}]),'<br>']},'</td>',

        # recipient group, Mailing List
        {_: :td, class: :group, property: To,
          c: {_: :a, :class => :to, style: 'background-color:'+c, c: e[0] && e[0].split(/@/)[0],
            href: e[0] && e[0].E.url+'?set=indexPO&p=sioc:addressed_to&view=page&v=threads'}},

        '</tr>']},'</table>',

     # link to unabbreviated content of message-set
     {_: :a, id: :down, c: '&darr;',
       href: env['REQUEST_PATH'] + env.q.merge({'view'=>'page','views'=>'timegraph,mail','arc'=>'/parent','v'=>'multi','sort'=>'dc:date','reverse'=>true}).qs}]}

  fn 'view/mail',->d,e{
    title = nil

    # JS/CSS dependencies
    [(H.once e,'mail.js',
      (H.css '/css/mail'), {_: :style, c: "a {background-color: #{E.cs}}"},
      (H.js '/js/mail'),
      (H.once e,:mu,(H.js '/js/mu')),

      # up to set-overview
      ({_: :a, id: :up, href: e['REQUEST_PATH'] + e.q.merge({'view' => 'page', 'v' => 'threads'}).qs, c: '&uarr;'} if d.keys.size > 2),

      # collapse/expand quoted content
      {id: :showQuote, c: :quotes, show: :true},{_: :style, id: :quote}),'<br>',

     # each message
     d.values.map{|m|

       # content available?
       [m.class == Hash && (m.has_key? E::SIOC+'content') &&
        
        {:class => :mail,
          
          c: [# link to self
              {_: :a, name: m.uri, href: m.url+'?graph=triplrHref', rel: :permalink, title: :raw, c: ' '},
              
              # To:, From: index search links
              [['sioc:has_creator',Creator],['sioc:addressed_to',To]].map{|a|
                m[a[1]].do{|m|
                  m.map{|f| f.respond_to?(:uri) &&
                    {_: :a, property: a[0], href: f.url+'?set=indexPO&p='+a[0]+'&view=page&views=timegraph,mail&arc=/parent&v=multi&c=8', c: f.uri}}}},

              # mailto URI with embedded reply metadata
              (m['/mail/reply_to']||m[Creator]).do{|r| r[0] && r[0].respond_to?(:uri) &&
                {_: :a, title: :reply, c: 'r',
                  href: "mailto:#{r[0].uri}?References=<#{m.uri}>&In-Reply-To=<#{m.uri}>&Subject=#{m[Title].join}"}},'<br clear=all>',

              # content
              {_: :pre,
                c: m[Content].map{|b|

                  # line count
                  i = 0

                  # HTML message content
                  b.class==String && b.              

                  # erase empty quoted lines
                  gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").

                  # each line
                  lines.to_a.map{|l|

                    # line identifier
                    f = m.uri + ':' + (i+=1).to_s
                    
                    # wrapper
                    {_: :span, 
                      
                      # is line quoted?
                      class: ((l.match /(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ? 'q' : 'u'), c:

                      # id
                      [{_: :a, id: f},

                       # line
                       l.chomp,

                       # link
                       (l.size > 64 &&
                        {_: :a, class: :line, href: '#'+f,c: '&#160;'}),

                     "\n" ]}}}}, # collate lines

              # title
              m[Title].do{|t|
                # only show if changed from previous
                title != t[0] && (
                 title = t[0] # update title
                 [{:class => :title, c: t.html, _: :a, href: m.url+'??=thread#'+m.uri},
                  '<br clear=all>'])}]}]}]}
  
  # set a default view for RFC822 and SIOC types
  [MIMEtype+'message/rfc822',
   SIOCt+'MailMessage'].
    map{|m| F['view/'+m] = F['view/mail'] }

end
