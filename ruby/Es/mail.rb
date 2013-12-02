watch __FILE__
class E

  # v1.2.7 -  apt-get install ruby-tmail
  def triplrTmail  ; require 'tmail'
    (TMail::Mail.load node).do{|m|      # parse
      d = m.message_id; return unless d # parse successful?
      e = d[1..-2]                      # unwrap id
      yield e, Type,    E[SIOCt + 'MailMessage']
      yield e, Type,    E[SIOC  + 'Post']
      yield e, Date,    m.date.iso8601 if m.date
      yield e, Content, m.decentBody
        [[:subject,Title],   # 0 accessor method
              [:to,To,true], # 1 predicate URI
              [:cc,To,true], # 2 node || literal
             [:bcc,To,true], # 3 unwrap id?
   [:friendly_from,SIOC+'name'],
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
    puts [:tMail,uri,e].join ' '
  end

  def triplrMail &f
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
