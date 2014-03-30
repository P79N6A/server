# -*- coding: utf-8 -*-
#watch __FILE__
class R

  # Message-ID -> storage path
  MessagePath = ->id{'/msg/' + id.h[0..2] + '/' + id} # String
  F['/mid/GET'] = -> e,r{R[MessagePath[e.base]].env(r).response} # HTTP

  fn '/thread/GET',-> e, r { m = {}
    R[MessagePath[e.stripDoc.basename]].walk SIOC+'reply_of', m
    return F[404][e,r] if m.empty?
    v = r.q['view'] ||= "timegraph"
    r['ETag'] = [(F['view/'+v] && v), m.keys.sort, r.format].h
    e.condResponse r.format, ->{e.render r.format, m, r}}

  # subtree-range over posts at mailing-address path
  F['/m/GET'] = -> e,r{
    if m = e.pathSegment.uri.match(/^\/m\/([^\/]+)$/)
      r.q['set']  ||= 'depth'
      r.q['view'] ||= 'threads'
      e.stripDoc.env(r).response
    else
      false
    end}

  # allow grep on address paths
  GREP_DIRS.push /^\/m\/[^\/]+\//

  # link a message to address paths
  IndexMail = ->doc, graph, host {
    graph.map{|u,r|
      a = [] # address references
      r[Creator].do{|c|a.concat c}
      r[To].do{|t|a.concat t}
      r[Date].do{|t|
        st = '/' + t[0][0..18].gsub('-','/').sub('T','.') + '.' + u.h[0..1] + '.e'
        a.map{|rel|
          doc.ln R[rel.uri.split('#')[0]+st]}}}}

  def triplrMailMessage &f
    addDocsJSON :triplrMail, @r['SERVER_NAME'], [SIOC+'reply_of'], IndexMail, &f
  end

  def mail
    Mail.read node if f
  end

  def triplrMail
    m = mail          ; return unless m              # mail
    id = m.message_id ; return unless id             # message-ID
    e = MessagePath[id.gsub(/[<>]/,'')]              # message URI
    yield e, DC+'identifier', id                     # origin-domain ID
#    yield e, DC+'source', self                       # source-file URI
    [R[SIOCt+'MailMessage'],                         # SIOC types
     R[SIOC+'Post']].map{|t|yield e, Type, t}        # RDF types

    m.from.do{|f|                                    # any authors?
      f.justArray.map{|f|                            # each author
        f = f.to_utf8
        creator = '/m/'+f+'#'+f                        # author URI
        yield e, Creator, R[creator]                   # message -> author
        yield creator, DC+'identifier', R['mailto:'+f] # author ID
                                                       # reply to
        r2 = m['List-Post'].do{|lp|lp.decoded[8..-2]} || # List-Post
             m.reply_to.do{|t|t[0]} ||                   # Reply-To
             f                                           # From
        yield e, SIOC+'reply_to',                      # reply URI
        R[URI.escape("mailto:#{r2}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{m.subject}&")+'#reply']}}

    yield e, Date, m.date.iso8601 if m.date          # date

    m.subject.do{|s| # subject
      s = s.to_utf8.hrefs
      yield e, Label, s
      yield e, Title, s}

    yield e, SIOC+'has_discussion',                  # thread
    R['/thread/'+id+'#'+e] if m.in_reply_to || m.references

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

    parts = m.all_parts.push m                       # parts

    parts.select{|p|                                 # text parts
      (!p.mime_type || p.mime_type=='text/plain') &&
      Mail::Encodings.defined?(p.body.encoding)      # decodable?
    }.map{|p|
      yield e, Content,
      H([{_: :pre, class: :mail, style: 'white-space: pre-wrap', # wrap body
           c: p.decoded.to_utf8.hrefs.gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted*empty lines
             l.match(/(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ?        # quoted?
             {_: :span, class: :q, depth: l.scan(/(&gt;)/).size, c: l} : l # wrap quotes
           }},(H.css '/css/mail')])}

    attache = -> { e.R.a('.attache').mk }   # filesystem container for attachments & parts

    htmlCount = 0
    parts.select{|p|p.mime_type=='text/html'}.map{|p| # HTML content
      html = attache[].as "page#{htmlCount}.html"     # name
      yield e, DC+'hasFormat', html                   # message -> HTML resource
      html.w p.decoded if !html.e                     # write content
      htmlCount += 1 }
                                                      # attached
    m.attachments.select{|p|Mail::Encodings.defined?(p.body.encoding)}.map{|p|
      name = p.filename.do{|f|f.to_utf8.do{|f|!f.empty? && f}} || (rand.to_s.h + '.' + (MIME.invert[p.mime_type] || 'bin').to_s)
      file = attache[].as name                        # name
      file.w p.body.decoded if !file.e                # write
      yield e, SIOC+'attachment', file                # message -> attached resource
      if p.main_type=='image'                         # image reference in HTML
        yield e, Content, H({_: :a, href: file.uri, c: [{_: :img, src: file.uri},p.filename]})
      end }

  end

  F['view/'+MIMEtype+'message/rfc822'] = NullView # hide file-container resource

  fn 'view/threads',->d,env{
    posts = d.resourcesOfType SIOC+'Post'
    threads = posts.group_by{|r| # group by Title
       [*r[Title]][0].do{|t|t.sub(/^[rR][eE][^A-Za-z]./,'')}}
    [F['view/'+HTTP+'Response'][{'#' => d['#']},env],'<br clear=all>',
     (H.css '/css/threads'),{_: :style, c: "body {background-color: ##{rand(2).even? ? 'fff' : '000'}}"},
     '<table>',
     threads.group_by{|r,k| # group by recipient
       k[0].do{|k| k[To].do{|o|o.head.uri}}}.
     map{|group,threads| c = R.cs
       ['<tr><td class=subject>',
        threads.map{|title,msgs| # thread
          [{_: :a, property: Title, :class => 'thread', style: "border-color:#{c}", href: '/thread/'+msgs[0].R.base,
             c: title.to_s.gsub(/[<>]/,'_').gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>')},
           (msgs.size > 1 && # more than one author
            ['<br>', msgs.map{|s| # show authors
                {_: :a, property: Creator, href: '/thread/'+s.R.base+'#'+s.uri, :class => 'sender', style: 'background-color:'+c,
                 c: s[Creator].do{|c|c[0].uri.split('#')[1].split('@')[0]}}}]),'<br clear=all>']},'</td>',
        ({_: :td, class: :group, property: To,
          c: {_: :a, :class => :to, style: 'background-color:'+c, c: group.abbrURI, href: group}} if group),
        '</tr>']},'</table>',
     {_: :a, id: :down, href: env['REQUEST_PATH'] + env.q.merge({'view'=>''}).qs, c: '↓'}]} # drill down to full view

end
