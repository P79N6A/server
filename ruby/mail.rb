#watch __FILE__
class E

  begin 
    require 'tmail'
  rescue LoadError => e
  end

  MessagePath = ->id{ h = id.h # hash identifier
    '/msg/' + h[0..2] + '/' + id}

  GREP_DIRS.push /\/m\/[^\/]+\// # allow grep within a single address

  F['/m/GET'] = -> e,r{
    if m = e.pathSegment.uri.match(/^\/m\/([^\/]+)$/)
      r.q['set'] = 'subtree'
      r.q['view'] ||= 'threads'
       e.response
    else
      false      
    end}

  def triplrTmail &f
    (TMail::Mail.load node).do{|m|      # load
      d = m.message_id; return unless d # parse successful?
      id = d[1..-2]                     # message-ID
      e = MessagePath[id]               # webized ID
      from = m.from[0].to_utf8          # author
      creator = '/m/'+from+'#'+from     # author URI
      yield e, DC+'identifier', id      # original ID
      yield e, DC+'source', self        # original file
      yield e, Type, E[SIOCt + 'MailMessage']
      yield e, Type, E[SIOC  + 'Post']
      yield e, Date, m.date.iso8601 if m.date
      yield e, Title, m.subject.to_utf8
      yield e, Creator, E[creator]
      yield e, SIOC+'has_discussion', E[e+'?graph=thread#discussion']
      yield creator, Name, m.friendly_from.to_utf8
      yield creator, DC+'identifier', E['mailto:'+from]
      yield e, SIOC+'reply_to',
      E[URI.escape("mailto:#{m.header['x-original-to']||from}?References=<#{e}>&In-Reply-To=<#{e}>&Subject=#{m.subject.to_utf8}&")+'#reply']

      %w{to cc bcc}.map{|to|
        m.send(to).do{|to| to.map{|to|
            to = to.to_utf8
            yield e, To, E['/m/'+to+'#'+to]
          }}}

      %w{in_reply_to references}.map{|ref|
        m.send(ref).do{|refs| refs.map{|r|
          yield e, SIOC+'reply_of', E[MessagePath[r[1..-2]]]}}}

      # RDF:HTML with self-contained minimal styling
      yield e, Content,
      H([{_: :pre, class: :mail, style: 'white-space: pre-wrap',
           c: m.concat_message(e.E,0,&f).gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted empty-lines
             l.match(/(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ? {_: :span, class: :q, c: l} : l # wrap quoted lines
           }},{_: :style, c: "pre.mail .q {background-color:#00f;color:#fff}\npre.mail a{background-color:#ef3}\npre.mail img {max-width:100%}"}])}
  rescue Exception => e
    puts e
  end

  def triplrMailMessage &f
    # indexing function, called on previously-unseen doc-graphs
    ix = ->doc, graph{
      graph.map{|u,r|
        a = [] # addresses
        r[Creator].do{|c|a.concat c}
        r[To].do{|t|a.concat t}
        r[Date].do{|t|
          st = '/'+t[0].gsub('-','/').sub('T','.').sub(/\+.*/,'.'+u.h[0..1]+'.e')
          a.map{|rel|
            doc.ln E[rel.uri.split('#')[0]+st]}}}}
    addDocs :triplrTmail, @r['SERVER_NAME'], [SIOC+'reply_of'], ix, &f
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
