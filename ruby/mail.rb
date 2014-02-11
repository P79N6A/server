watch __FILE__
class R

  MessagePath = ->id{'/msg/' + id.h[0..2] + '/' + id}

  GREP_DIRS.push /^\/m\/[^\/]+\// # allow grep within a single address

  F['/m/GET'] = -> e,r{
    # set overview(summary) view and start a depth-first view of message tree of this address
    if m = e.pathSegment.uri.match(/^\/m\/([^\/]+)$/)
      r.q['set'] ||= 'depth'
      r.q['view'] ||= 'threads'
       e.response
    else
      false      
    end}

  IndexMail = ->doc, graph, host {
    graph.map{|u,r|
      a = [] # address references
      r[Creator].do{|c|a.concat c}
      r[To].do{|t|a.concat t}
      r[Date].do{|t|
        st = '/'+t[0].gsub('-','/').sub('T','.').sub(/\+.*/,'.'+u.h[0..1]+'.e')
        a.map{|rel|
          doc.ln R[rel.uri.split('#')[0]+st]}}}}

  def triplrMailMessage &f
    addDocs :triplrMail, @r['SERVER_NAME'], [SIOC+'reply_of'], IndexMail, &f
  end

  def triplrMail &f
    (f && (Mail.read node)).do{|m|
      id = m.message_id; return unless id # message-ID
      e = MessagePath[id]               # webized ID
      from = m.from.do{|f|f[0].to_utf8} # author
      return unless from
      creator = '/m/'+from+'#'+from     # author URI
      yield e, DC+'identifier', id      # original ID
      yield e, DC+'source', self        # original file
      yield e, Type, R[SIOCt + 'MailMessage']
      yield e, Type, R[SIOC  + 'Post']
      yield e, Date, m.date.iso8601 if m.date
      m.subject.do{|s|
        s = s.to_utf8
        yield e, Title, s
      yield e, SIOC+'reply_to',R[URI.escape("mailto:#{m.header['x-original-to']||from}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{s}&")+'#reply']}
      yield e, Creator, R[creator]
      yield e, SIOC+'has_discussion', R[e+'?graph=thread&view=timegraph#discussion']
#      yield creator, Name, m.friendly_from.to_utf8
      yield creator, DC+'identifier', R['mailto:'+from]


      %w{to cc bcc}.map{|to|
        m.send(to).do{|to| to.justArray.map{|to|
            to.do{|to|
              to.to_utf8
              yield e, To, R['/m/'+to+'#'+to]}}}}

      %w{in_reply_to references}.map{|ref|
        m.send(ref).do{|rs| (rs.class == Array ? rs : [rs]).map{|r|
          yield e, SIOC+'reply_of', R[MessagePath[r]]}}}
      m.in_reply_to.do{|r| yield e, SIOC+'has_parent', R[MessagePath[r]]}

      # RDF:HTML message-body
      yield e, Content,
      H([{_: :pre, class: :mail, style: 'white-space: pre-wrap',
           c: m.text_part.to_s.to_utf8.hrefs.gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted empty-lines
             l.match(/(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ? {_: :span, class: :q, depth: l.scan(/(&gt;)/).size, c: l} : l # quotes
           }},(H.css '/css/mail',true)])}
  end

  F['view/'+MIMEtype+'message/rfc822'] = NullView # hide containing file in default render

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
            p = a.as(part['content-type']['name'] || (partCount.to_s + '.' + (R::MIME.invert[part.content_type] || '.bin').to_s))
            p.w part.body if !p.e # write attachment into message container
            partCount += 1        # display images
            yield i.uri, R::SIOC+'attachment', p
            '<a href="'+p.uri+'">'+(part.main_type=='image' ? '<img src="'+p.uri+'">' : '')+p.uri.label+"</a><br>\n"
          end
        }.join
      else # just a part
        unicode_body.do{|b|
          if content_type && content_type.match(/html/)
            R::F['cleanHTML'][b]
          else
            b.hrefs true
          end}
      end
    end 
  end
end

