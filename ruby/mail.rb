#watch __FILE__
class E

  fn 'view/mail',->d,e{
    title = nil

    # JS/CSS
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
          
          c: [# message link
              {_: :a, name: m.uri, href: m.url+'?view=base', rel: :raw, title: :raw, c: '&nbsp;'},
              
              # To:, From: index search links
              [['sioc:has_creator',Creator],['sioc:addressed_to',To]].map{|a|
                m[a[1]].do{|m|
                  m.map{|f| f.respond_to?(:uri) &&
                    {_: :a, property: a[0], href: f.url+'?set=indexPO&p='+a[0]+'&view=page&v=threads&c=12', c: f.uri}}}},

              # mailto URI with embedded reply metadata
              (m['/mail/reply_to']||m[Creator]).do{|r| r[0] && r[0].respond_to?(:uri) &&
                {_: :a, title: :reply, c: 're',
                  href: "mailto:#{r[0].uri}?References=<#{m.uri}>&In-Reply-To=<#{m.uri}>&Subject=#{m[Title].join}"}},

              {class: :timestamp, c: m[Date].do{|d|d.map{|d|d.to_s[0..18]}}}, '<br clear=all>',

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
