#watch __FILE__
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

  # E['/m/2013/10/18/'].c[4].graph

  def triplrMail; require 'tmail'

    # read message
    i = -> i {E i[1..-2]}                 # Message-ID -> E
    (TMail::Mail.load node).do{|m|        # parse
      d = m.message_id; return unless d   # parse successful?
      e = i[d]                            # Message resource
      e.e || (                            # Message-ID locatable?
       ln e                               # create message-id path 
       # index previously unseen mail
       self.index 'sioc:has_creator', m.from[0].E    # index From
       m.to.do{|t|self.index 'sioc:addressed_to', t[0].E}  # index To

       %w{in_reply_to references}.map{|p| # reference arcs
        m.send(p).do{|os| os.map{|o|      # lookup references
        e.index E['sioc:reply_of'],i[o].opaque}}}) # index ref

      # yield triples
      yield e.uri, Type,    E[SIOCt+'MailMessage']
      yield e.uri, Date,    m.date.iso8601    if m.date
      yield e.uri, Content, m.decentBody
        [[:subject,Title],
              [:to,To,true],
              [:cc,To,true],
             [:bcc,To,true],
   [:friendly_from,SIOC+'name'],
            [:from,Creator,true],
        [:reply_to,'/mail/reply_to',true],
     [:in_reply_to,'/parent',true,true],
     [:in_reply_to,SIOC+'reply_of',true,true],
      [:references,SIOC+'reply_of',true,true],
        ].each{|a| m.send(a[0]).do{|o| [*o].map{|o|
            yield e.uri,a[1],                        # skip empty String values 
            (a[2] ? (a[3] ? i[o] : o.E) : o.to_utf8) unless o.match(/\A[, \n]*\Z/)}}}}

  rescue Exception => e
    puts [:mail,uri,e].join(' ')
  end

  fn 'graph/thread',->d,_,m{d.walk SIOC+'reply_of',m}

  # overview of a message set
  fn 'view/threads',->d,env{

    # occurrence-count statistics
    g = {}
    d.map{|_,m|
      m[To].do{|to|to.map{|t|
          g[t.uri]||=0
          g[t.uri]=g[t.uri].succ}}}

    # CSS
    [(H.css '/css/mail.threads'),{_: :style, c: "body {background-color: ##{rand(2).even? ? 'fff' : '000'}}"},

     ([{_: :a, class: :narrowP, href: '/@'+env.q['p']+'?set=indexP&view=page&v=linkPO&c=12', c: env.q['p']},'&nbsp;',
       {_: :a, class: :current, href: '/m?y=day', c: ' '},'&nbsp;',
       {_: :a, class: :narrowPO, href: E[env['uri']].url+'?set=indexPO&view=page&v=threads&c=32&p='+env.q['p'], c: env['uri']}
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


  # show a set of messages
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
      {id: :showQuote, c: :quote, show: :true},{_: :style, id: :quote}),

     # each message
     d.values.map{|m|

       # content available?
       [m.class == Hash && (m.has_key? E::SIOC+'content') &&
        
        {:class => :mail,
          
          c: [# link to self
              {_: :a, name: m.uri, href: m.url, rel: :permalink, title: :link, c: ' '},
              
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
  
  # set a default view for MIME and SIOC types
  [MIMEtype+'message/rfc822',
   SIOCt+'MailMessage'].
    map{|m| F['view/'+m] = F['view/mail'] }

end

module TMail
  class Mail
    def unicode_body
      unquoted_body.to_utf8
    end
    def decentBody
      unHTML=->t{t.split(/<body[^>]*>/)[-1].split(/<\/body>/)[0]}
      if multipart?
        parts.collect{ |part|
          c = part["content-type"]
          if part.multipart?
            part.decentBody
          elsif header.nil?
            ""
          elsif !attachment?(part) && c.sub_type != 'html'
            part.unicode_body.hrefs(true)
          else
            (c["name"]||'attach').do{|a|
              message_id ? (message_id[1..-2]+'/'+a).E.do{|i|
                i.w part.body if !i.e
                '<a href='+i.url+'>'+(part.main_type=='image' ? '<img src="'+i.url+'">' : a)+"</a><br>\n"
              } : ""};end
        }.join

      else
        unicode_body.do{|b|content_type&&content_type.match(/html/) ? unHTML.(b) : b.hrefs(true)}
      end
    rescue
      ''
    end 
  end
end

class String; def is_binary_data?; true; end; end
