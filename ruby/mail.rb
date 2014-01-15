#watch __FILE__
class E

  begin 
    require 'tmail'
  rescue LoadError => e
  end

  def triplrTmail &f
    messagePath = ->id{
      h = id.h # hash
      '/msg/' + h[0..1] + '/' + h[2] + '/' + id}

    (TMail::Mail.load node).do{|m|      # load
      d = m.message_id; return unless d # parse successful?
      id = d[1..-2]                     # message-ID
      e = messagePath[id]               # webized ID
      yield e, DC+'identifier', id      # original ID
      yield e, DC+'source', self        # original file
      yield e, Type, E[SIOCt + 'MailMessage']
      yield e, Type, E[SIOC  + 'Post']
      yield e, Date, m.date.iso8601 if m.date
      yield e, Title, m.subject.to_utf8
      yield e, SIOC+'name', m.friendly_from.to_utf8
      yield e, Creator, E['/m/'+m.from[0].to_utf8]
      m.header['x-original-to'].do{|f|
        yield e, SIOC+'reply_to', E[URI.escape "mailto:#{f}?References=<#{e}>&In-Reply-To=<#{e}>&Subject=#{m.subject.to_utf8}"] }
      %w{to cc bcc}.map{|to|
        m.send(to).do{|to| to.map{|to|
          yield e, To, E['/m/'+to.to_utf8]}}}
      %w{in_reply_to references}.map{|ref|
        m.send(ref).do{|refs| refs.map{|r|
          yield e, SIOC+'reply_of', E[messagePath[r[1..-2]]]}}}
      # local markup for RDF:HTML without specialized view
      yield e, Content,
      H([{_: :pre, class: :mail, style: 'white-space: pre-wrap',
           c: m.concat_message(e.E,0,&f).gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted empty-lines
             l.match(/(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ? {_: :span, class: :q, c: l} : l # wrap quoted lines
           }},
         {_: :style, c: "pre.mail .q {background-color:#00f;color:#fff}\npre.mail a{background-color:#ef3}\npre.mail img {max-width:100%}"}])}
  rescue Exception => e
    puts e
  end

  def triplrMailMessage &f
    insertDocs :triplrTmail, nil, [To,SIOC+'reply_of'], &f
  end
=begin
 there's another mail library called Mail, as of v2.5.4 takes 50x as long as tmail (apt-get install ruby-tmail)
HEAD 200 http://m/m/2013/12/01/?nocache=&triplr=triplrMail curl/7.33.0  5.4003388
HEAD 200 http://m/m/2013/12/01/?nocache=&triplr=triplrTmail curl/7.33.0  0.1198720

almost a copy of above works but identifiers are not wrapped in <> - with caching it might be fast enough..

=end

end

module TMail
  class Mail
    def unicode_body
      unquoted_body.to_utf8
    end
    def concat_message i, partCount=0, &f
      if multipart?
        parts.map{|part|
          if part.multipart?   # and even more nested parts..
            part.concat_message i, partCount, &f
          elsif !attachment?(part) && part.sub_type != 'html'
            part.unicode_body.hrefs true
          else # attachment
            a = i.a('.attache').mk # create container
            p = a.as(part['content-type']['name'] || (partCount.to_s + '.' + (E::MIME.invert[part.content_type] || '.bin').to_s))
            p.w part.body if !p.e # write attachment into message container
            partCount += 1        # display images
            yield i.uri, E::SIOC+'attachment', p
            '<a href="'+p.uri+'">'+(part.main_type=='image' ? '<img src="'+p.uri+'">' : '')+p.uri.label+"</a><br>\n"
          end
        }.join
      else # just a part
        unicode_body.do{|b|
          if content_type && content_type.match(/html/)
           (b.split /<body[^>]*>/)[-1].split(/<\/body>/)[0]
          else
            b.hrefs true
          end}
      end
    end 
  end
end

class String; def is_binary_data?; true; end; end
