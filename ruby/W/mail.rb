# -*- coding: utf-8 -*-
#watch __FILE__
class String; def is_binary_data?; true; end; end
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
class E
  F["?"]||={};F["?"].update({
   'thread'=>{'graph'=>'thread','sort' => 'dc:date','reverse' => nil,'view' => 'mail'},
   'ann'=>{'view'=>'threads','match' => /[^a-zA-Z][Aa][Nn][nN]([oO][uU]|[^a-zA-Z])/,'matchP' => 'dc:title'}})

  def triplrMail
    require 'tmail'
    i = -> i {E i[1..-2]}                 # Message-ID -> E
    (TMail::Mail.load node).do{|m|        # parse
      d = m.message_id; return unless d   # parse successful?
      e = i[d]                            # Message resource
      e.e || (                            # Message-ID locatable?
              ln e
       %w{in_reply_to references}.map{|p| # message arcs
          m.send(p).do{|o|                # index connections (fs)
            o.map{|o| e.index SIOC+'reply_of', i[o] }}}
               e.ln '/' + m.date.iso8601[0..12].gsub(/[^\d]/,'/') + '/' + e.uri # date/hour index
                   self.index Creator, m.from[0].E # index From
                   self.index      To, m.to[0].E   # index To
               )
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
            yield e.uri,a[1],(a[2] ? (a[3] ? i[o] : o.E) : o.to_utf8) unless o.match(/\A[, \n]*\Z/)}}}}
  rescue Exception => e
    puts [:mail,uri,e].join(' ')
  end

  fn 'graph/thread',->d,_,m{d.walk SIOC+'reply_of',m}

  # an overview of messages in a resource set
  fn 'view/threads',->d,env{g={}
    d.map{|_,m|
      m[To].map{|t|
        g[t.uri]||=0
        g[t.uri]=g[t.uri].succ}}
    [(H.css '/css/mail'),'<table>',
     d.values.group_by{|r|[*r[Title]][0].sub(/^[rR][eE][^A-Za-z]./,'')
     }.group_by{|r,k|
       k[0].do{|k|
         k[To].do{|o|o.sort_by{|t|g[t.uri]}.reverse.head.uri}}
     }.map{|e| c='#%06x' % rand(16777216)
       ['<tr><td class=subject>',
        e[1].sort_by{|m|m[1].size}.reverse.map{|t|
          [{_: :a, property: Title, :class => 'thread', style: "border-color:#{c}", href: t[1][0].url+'??=thread',
             c: t[0].to_s.gsub(/[<>]/,'_').gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>')},
           (t[1].size > 1 &&
            ['<br>',t[1].map{|s|
               [{_: :a, property: Creator,href: s.url,:class => 'sender', style: 'background-color:'+c,
                  c: s[SIOC+'name'][0].split(/\W/,2)[0]},' ']}]),'<br>']},'</td>',
        {_: :td, class: :group, property: To, c: {_: :a, :class => :to, style: 'background-color:'+c,
          c: e[0] && e[0].split(/@/)[0], href: e[0] && e[0].E.url+'?,=sioc:addressed_to&view=page&v=threads'}},
        '</tr>']},'</table>',
     {_: :a, :class => :show, c: :content,href: env['REQUEST_PATH']+env.q.except('v').update({'view' => 'mail'}).qs}]}

  # show a set of messages
  fn 'view/mail',->d,e{
    title = nil

    # JS/CSS dependencies
    [(H.once e,'mail.js',
      (H.css '/css/mail'),
      (H.js '/js/mail'),
      (H.once e,:mu,(H.js '/js/mu')),

      # collapse/expand quoted content
      {id: :showQuote, c: :quote, show: :true},{_: :style, id: :quote}),

     # each message
     d.values.map{|m|

       # fragment identifier
       [{_: :a, name: m.uri},

        # content available?
        m.class == Hash && (m.has_key? E::SIOC+'content') &&
        
        {:class => :mail,
          
          c: [# title
              m[Title].do{|t|
                # only show if changed from previous
                title != t[0] && (
                 title = t[0] # update title
                 [{:class => :title, c: '███'+t.html, _: :a, href: m.url, style: "color: #{E.c}"},
                  '<br clear=all>'])},

              # link to self
              {_: :a, href: m.url, rel: :permalink, title: :link, c: ' '},
              
              # To:, From: index search links
              [['sioc:has_creator',Creator],['sioc:addressed_to',To]].map{|a|
                m[a[1]].do{|m|
                  m.map{|f| f.respond_to?(:uri) &&
                    {_: :a, property: a[0], href: f.url+'?set=index&p='+a[0]+'&view=page&v=threads&c=48', c: f.uri}}}},

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
                        {_: :a, class: :line, href: '#'+f,c: '↵'}),

                     "\n" ]}}}}]}]}]} # collate
  
  # default view for these MIME and SIOC types
  [MIMEtype+'message/rfc822',
   SIOCt+'MailMessage'].
    map{|m| F['view/'+m] = F['view/mail'] }

end
