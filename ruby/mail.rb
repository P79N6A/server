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

  def mail
    Mail.read node if f
  end

  def triplrMail
    m = mail          ; return unless m      # mail
    id = m.message_id ; return unless id     # message-ID
    e = MessagePath[id]                              # message URI
    yield e, DC+'identifier', id                     # origin-domain ID
    yield e, DC+'source', self                       # source-file URI
    [R[SIOCt+'MailMessage'],                         # SIOC types
     R[SIOC+'Post']].map{|t|yield e, Type, t}        # RDF types

    m.from.do{|f|f[0].to_utf8}.do{|f|                # has author?
      creator = '/m/'+f+'#'+f                        # author URI
      yield e, Creator, R[creator]                   # message -> author
      yield creator, DC+'identifier', R['mailto:'+f] # author ID
      # yield creator, Name, m.friendly_from.to_utf8 # author name

      yield e, SIOC+'reply_to',                      # reply URI
      R[URI.escape("mailto:#{m.header['x-original-to']||f}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{m.subject}&")+'#reply']}

    yield e, Date, m.date.iso8601 if m.date          # date

    m.subject.do{|s|yield e, Title, s.to_utf8}       # subject

    yield e, SIOC+'has_discussion',                  # thread
    R[e+'?graph=thread&view=timegraph#discussion']

    %w{to cc bcc}.map{|to|                           # reciever fields
      m.send(to).do{|to|                             # has field?
        to.justArray.map{|to|                        # each recipient
          to.do{|to|                                 # non-nil? 
            to = to.to_utf8                          # UTF-8
            yield e, To, R['/m/'+to+'#'+to]}}}}      # recipient URI

    %w{in_reply_to references}.map{|ref|             # reference predicates
     m.send(ref).do{|rs| rs.justArray.map{|r|        # indirect-references
      yield e, SIOC+'reply_of', R[MessagePath[r]]}}} # reference URI

    m.in_reply_to.do{|r|                             # direct-reference predicate
      yield e, SIOC+'has_parent', R[MessagePath[r]]} # reference URI

    m.all_parts.push(m).map{|p|                      # parts
      if p.text? && p.sub_type!='html'               # text part
        c = p.decoded.to_utf8                        # decode
        yield e, Content,                            # content
        H([{_: :pre, class: :mail, style: 'white-space: pre-wrap', # wrap body
             c: c.hrefs.gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted*empty lines
               l.match(/(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ? # quoted lines
               {_: :span, class: :q, depth: l.scan(/(&gt;)/).size, c: l} : l # wrap quotes
             }},(H.css '/css/mail',true)])
      else
        attache = e.R.a('.attache').mk # filesystem container
        file = attache.as(p.filename.do{|f|f.to_utf8} || (rand.to_s.h + '.' + (R::MIME.invert[p.mime_type] || 'bin').to_s))
        file.w p.body if !file.e # write part
        yield e, R::SIOC+'attachment', file
        if p.main_type=='image'
          yield e, Content, H({_: :a, href: file.uri, c: [{_: :img, src: file.uri},p.filename]})
        end
      end if Mail::Encodings.defined?(p.body.encoding)}
  end

  F['view/'+MIMEtype+'message/rfc822'] = NullView # hide container-file metadata in default view

end
