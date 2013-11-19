class E
  
  # TMail version: 1.2.7.1-4
  # apt-get install ruby-tmail

  def triplrTmail                         ; require 'tmail'

    # read message
    i = -> i {E i[1..-2]}                 # Message-ID -> E
    (TMail::Mail.load node).do{|m|        # parse
      d = m.message_id; return unless d   # parse successful?
      e = i[d]                            # Message resource
      e.e || (                            # Message-ID locatable?
       ln e                               # create message-id path 
       # index previously unseen mail
       # TODO move this outside the triplr, when triplrMail is written
       self.index Creator,  m.from[0].E   # index From
       m.to.do{|t|self.index To, t[0].E}  # index To

       %w{in_reply_to references}.map{|p|
        m.send(p).do{|os| os.map{|o|
         e.index SIOC+'reply_of', i[o]}}}) # index references

      # yield triples
      yield e.uri, Type,    E[SIOCt + 'MailMessage']
      yield e.uri, Type,    E[SIOC  + 'Post']
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

  alias_method :triplrMail, :triplrTmail

  # pure-ruby mail is only 10x (vs 100x) slower than C-ext based TMail w/ new parser
  # API is mostly identical, URIs strings arent <>-wrapped
  # TODO replace this msg with triplrMail if anyone wants it

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
