watch __FILE__
class E

  def triplrTmail &f
    messagePath = ->id{
      '/msg/' + id.h[0..1] + '/' + id}

    (TMail::Mail.load node).do{|m|      # load
      d = m.message_id; return unless d # parse successful?
      id = d[1..-2]                     # message-ID
      e = messagePath[id]               # webized ID
      yield e, DC+'identifier', id      # original ID
      yield e, Type, E[SIOCt + 'MailMessage']
      yield e, Type, E[SIOC  + 'Post']
      yield e, Date, m.date.iso8601 if m.date
      yield e, Title, m.subject.to_utf8
      yield e, SIOC+'name', m.friendly_from.to_utf8
      yield e, Creator, E['/mail/'+m.from[0].to_utf8]
      m.header['x-original-to'].do{|f|
        yield e, SIOC+'reply_to', E["mailto:#{f}?References=<#{e}>&In-Reply-To=<#{e}>&Subject=#{m.subject.to_utf8}"] }
      %w{to cc bcc}.map{|to|
        m.send(to).do{|to| to.map{|to|
          yield e, To, E['/mail/'+to.to_utf8]}}}
      %w{in_reply_to references}.map{|ref|
        m.send(ref).do{|refs| refs.map{|r|
          yield e, SIOC+'reply_of', E[messagePath[r[1..-2]]]}}}
      yield e, Content, H([{_: :pre, class: :mail, style: 'white-space: pre-wrap',
                            c: m.decentBody.gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted emptylines , tag quoted lines
                              {_: :span, class: ((l.match /(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ? 'q' : 'u'), c: [ l.chomp, "\n" ]}}},
                           {_: :style, c: "pre.mail .q {background-color:#000;color:#fff}\npre.mail a {background-color: #91acb3;color:#fff}"}])}
  rescue Exception => e
    puts e
  end

  begin 
    require 'tmail'
  rescue LoadError => e
  end

=begin

TMail 1.2.7 takes 2% time of Mail 2.5.4

HEAD 200 http://m/m/2013/12/01/?nocache=&triplr=triplrMail curl/7.33.0  5.4003388
HEAD 200 http://m/m/2013/12/01/?nocache=&triplr=triplrTmail curl/7.33.0  0.1198720

default can be tweaked in #triplrMailMessage

=end


  def triplrMail
    require 'mail'
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
        [:reply_to,SIOC+'reply_to',true],
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
