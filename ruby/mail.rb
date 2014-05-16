# -*- coding: utf-8 -*-
#watch __FILE__
class R

  MessagePath = ->id{
    id = id.gsub /[^a-zA-Z0-9\.\-@]/, ''
    '/msg/' + id.h[0..2] + '/' + id}

  GET['/mid'] = -> e,r{R[MessagePath[e.basename]].setEnv(r).response}

  GET['/thread'] = -> e, r {
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of', m
    return E404[e,r] if m.empty?
    return [406,{},[]] unless Render[r.format]

    m['#'] = {
      'uri' => e.uri,
      Type => [R[LDP+'BasicContainer'],
               R[SIOC+'Thread']],
      LDP+'contains' => m.keys.map(&:R)}

    v = r.q['view'] ||= "timegraph"
    r[:Response]['Access-Control-Allow-Origin'] = r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*'
    r[:Response]['Content-Type'] = r.format
    r[:Response]['ETag'] = [(View[v] && v), m.keys.sort, r.format].h

    e.condResponse ->{Render[r.format][m, r]}}

  GET['/m'] = -> e,r{
    if m = e.justPath.uri.match(/^\/m\/([^\/]+)\/$/)
      r.q['c'] ||= 16
      r.q['set']  ||= 'page'
      r.q['view'] ||= 'threads'
      nil
    end}

  GREP_DIRS.push /^\/m\/[^\/]+\//

  def mail; Mail.read node if f end

  def triplrMail &b
    m = mail          ; return unless m              # mail
    id = m.message_id ; return unless id             # message-ID
    e = MessagePath[id]                              # message URI

    yield e, DC+'identifier', id                     # origin-domain ID

    [R[SIOCt+'MailMessage'],                         # SIOC types
     R[SIOC+'Post']].map{|t|yield e, Type, t}        # RDF types

    list = m['List-Post'].do{|l|l.decoded[8..-2]}    # list ID
    m['List-Id'].do{|name|
      name = name.decoded
      dir = '/m/' + list                             # list Container
      group = dir + '#' + list                       # list URI
      yield group, Type, R[FOAF+'Group']             # list class
      yield group, FOAF+'mbox', R['mailto:'+list]    # list address
     (yield group, SIOC+'name',name.gsub(/[<>&]/,'') # list name
            ) unless name[1..-2] == list
      yield group, SIOC+'has_container', dir.R
    } if list

    m.from.do{|f|                                    # any authors?
      f.justArray.map{|f|                            # each author
        f = f.to_utf8
        creator = '/m/'+f+'#'+f                      # author URI
        yield e, Creator, R[creator]                 # message -> author
                                                     # reply target
        r2 = list ||                                 #  List
             m.reply_to.do{|t|t[0]} ||               #  Reply-To
             f                                       #  From
        yield e, SIOC+'reply_to',                    # reply URI
        R[URI.escape("mailto:#{r2}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{m.subject}&")+'#reply']}}

    m[:from].addrs.head.do{|a|                      # author address
      addr = a.address                              # author ID
      name = a.display_name || a.name               # author name
      dir = '/m/'+addr                              # author Container
      author = dir+'#'+addr                         # author URI
      yield author, DC+'identifier', addr
      yield author, Type, R[FOAF+'Person']
      yield author, FOAF+'mbox', R['mailto:'+addr]
      yield author, SIOC+'name', name
      yield author, SIOC+'has_container', dir.R
    }

    yield e, Date, m.date.iso8601 if m.date          # date

    m.subject.do{|s| # subject
      s = s.to_utf8.hrefs
      yield e, Label, s
      yield e, Title, s}

    yield e, SIOC+'has_discussion', R['/thread/'+id] # thread

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

    htmlFiles, parts = m.all_parts.push(m).partition{|p|p.mime_type=='text/html'} # parts

    parts.select{|p| (!p.mime_type || p.mime_type=='text/plain') &&
      Mail::Encodings.defined?(p.body.encoding)      # decodable?
    }.map{|p|
      yield e, Content,
      H([{_: :pre, class: :mail, style: 'white-space: pre-wrap',
           c: p.decoded.to_utf8.hrefs.gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted*empty lines
             l.match(/(^\s*(&gt;|On[^\n]+(said|wrote))[^\n]*)\n/) ?        # quoted?
             {_: :span, class: :q, depth: l.scan(/(&gt;)/).size, c: l} : l # wrap quotes
           }},(H.css '/css/mail')])}

    attache = -> { e.R.a('.attache').mk }   # filesystem container for attachments & parts

    htmlCount = 0
    htmlFiles.map{|p| # HTML content
      html = attache[].child "page#{htmlCount}.html"  # name
      yield e, DC+'hasFormat', html                   # message -> HTML resource
      html.w p.decoded if !html.e                     # write content
      htmlCount += 1 }

    parts.select{|p|p.mime_type=='message/rfc822'}.map{|m| # recursive inline-mail (digests + forwards)
      f = attache[].child 'msg.' + rand.to_s.h
#      yield e, LDP+'contains', f
      f.w m.body.decoded if !f.e
      f.triplrMail &b
    }

    m.attachments.                                    # attached
      select{|p|Mail::Encodings.defined?(p.body.encoding)}.map{|p|
      name = p.filename.do{|f|f.to_utf8.do{|f|!f.empty? && f}} || (rand.to_s.h + '.' + (MIME.invert[p.mime_type] || 'bin').to_s)
      file = attache[].child name                     # name
      file.w p.body.decoded if !file.e                # write
      yield e, SIOC+'attachment', file                # message -> attached resource
      if p.main_type=='image'                         # image reference in HTML
        yield e, Content, H({_: :a, href: file.uri, c: [{_: :img, src: file.uri},p.filename]})
      end }
  end

  def triplrMailMessage &f
    addDocsJSON :triplrMail, @r['SERVER_NAME'], [SIOC+'reply_of'], IndexMail, &f
  end

  IndexMail = ->doc, graph, host {
    graph.map{|u,r|      a = []
   r[Creator].do{|c|a.concat c}
        r[To].do{|t|a.concat t}
      r[Date].do{|t| x = '/' + t[0][0..18].gsub('-','/').sub('T','.') + '.' + u.h[0..1] + '.e'
        a.map{|rel| doc.ln_s R[rel.uri.split('#')[0]+x]}}}} # link msg <> address

  View['threads'] = -> d,env {
    posts = d.resourcesOfType SIOCt+'MailMessage'

    weight = {}
    posts.map{|p| p[To].justArray.map(&:maybeURI).map{|a|
        weight[a] ||= 0
        weight[a] += 1}}

    threads = posts.group_by{|r|
      r[Title].do{|t|
        t[0].noHTML.
        gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>').
        sub(/\b[rR][eE]: /,'')}}

    groups = threads.group_by{|_,posts|
      score = {}
      posts.map{|post|
        post[To].justArray.map(&:maybeURI).map{|a|
          score[a] ||= 0
          score[a] += weight[a] || 1}}
      score.invert.max[1]}

    [View[LDP+'Resource'][d,env],
     {_: :table, c: groups.map{|group,threads| # each group
         color = 'background-color:' + R.cs
         {_: :tr, c: [{_: :td,
           c: threads.map{|title,msgs| # each thread
             [{_: :a, class: 'thread', style: "border-color:#{c}", href: '/thread/'+msgs[0].R.basename, c: title},
              msgs.map{|s| s[Creator].justArray.select(&:maybeURI).map{|cr| # each message
                  [' ',{_: :a, href: '/thread/'+s.R.basename+'#'+s.uri, class: 'sender', style: color,
                     c: cr.R.fragment.do{|f| f.split('@')[0] } || cr.uri}]}},'<br>']}},
               group.do{|g|{_: :td, class: :group, c: {_: :a, :class => :to, style: color, c: g.R.abbr, href: g}}}]}}}, # group Identity
     (H.css '/css/threads', true)]}

end
