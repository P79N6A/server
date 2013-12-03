#watch __FILE__
class E
=begin

TMail 1.2.7 uses 2% time of Mail 2.5.4

HEAD 200 http://m/m/2013/12/01/?nocache=&triplr=triplrMail curl/7.33.0  5.4003388
HEAD 200 http://m/m/2013/12/01/?nocache=&triplr=triplrTmail curl/7.33.0  0.1198720

Mail is used as a fallback (adjust in #triplrMailMessage)

 apt-get install ruby-tmail

=end

%w{mail tmail}.map{|lib|
    begin 
      require lib 
    rescue LoadError => e
      puts e
    end}

  def triplrTmail &f
    (TMail::Mail.load node).do{|m| # parse
      d = m.message_id; return unless d  # parse successful?
      e = d[1..-2]                       # unwrap identifier
      yield e, Type,    E[SIOCt + 'MailMessage']
      yield e, Type,    E[SIOC  + 'Post']
      yield e, Date,    m.date.iso8601 if m.date
      yield e, Content, m.decentBody
      yield e, '/mail/reply_to', E[m.header['x-original-to'].to_s]
        [[:subject,Title],      # row index
              [:to,To,true],    # 0 accessor method
              [:cc,To,true],    # 1 predicate URI
             [:bcc,To,true],    # 2 node || literal
   [:friendly_from,SIOC+'name'],# 3 unwrap id?
            [:from,Creator,true],
        [:reply_to,'/mail/reply_to',true],
     [:in_reply_to,SIOC+'reply_of',true,true],
      [:references,SIOC+'reply_of',true,true],
        ].each{|a| # field
        m.send(a[0]).do{|o| [*o].map{|o|
            unless o.match /\A[, \n]*\Z/ # skip "empty" values
              yield e, a[1], (a[2] ? (a[3] ? o[1..-2] : o).E : o.to_utf8)
            end}}}}

  rescue Exception => e
    puts [uri,e,e.backtrace[0]].join ' '
    triplrMail &f
  end

  def triplrMail
    (f && (Mail.read node)).do{|m|
      e = m.message_id; return unless e  # parse successful?
      yield e, Type,    E[SIOCt + 'MailMessage']
      yield e, Type,    E[SIOC  + 'Post']
      yield e, Date,    m.date.iso8601 if m.date
      yield e, Content, m.body.decoded.to_utf8
        [[:subject,Title],
              [:to,To,true],
              [:cc,To,true],
             [:bcc,To,true],
            [:from,Creator,true],
        [:reply_to,'/mail/reply_to',true],
     [:in_reply_to,SIOC+'reply_of',true],
      [:references,SIOC+'reply_of',true],
        ].each{|a| # field
        m.send(a[0]).do{|o| [*o].map{|o|
            yield e, a[1], (a[2] ? o.E : o.to_utf8)
          }}}}
  end

  def triplrMailMessage &f
    insertDocs :triplrTmail, nil, [Creator,To,SIOC+'reply_of'], &f
  end

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
            # give attachments a URI and make them locatable
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
