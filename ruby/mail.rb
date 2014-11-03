# -*- coding: utf-8 -*-
#watch __FILE__
class R

  MessagePath = ->id{ # message-ID -> path
    id = id.gsub /[^a-zA-Z0-9\.\-@]/, ''
    '/msg/' + id.h[0..2] + '/' + id}

  AddrPath = ->address{ # address -> path
    a = address.downcase
    name = a.split('@')[0]
    '/address/' + a[0] + '/' + a + '/' + name + '#' + name}

  GET['/mid'] = -> e,r{R[MessagePath[e.basename]].setEnv(r).response} # message-ID lookup
  GET['/msg'] = -> e,r{e.path=='/msg/' ? E404[e,r] : nil}
  
  GET['/thread'] = -> e, r {
    return [406,{},[]] unless Render[r.format]
    m = {} # graph
    R[MessagePath[e.basename]].walk SIOC+'reply_of', m # find graph
    return E404[e,r] if m.empty?
    m['#'] = { 'uri' => e.uri, # thread-meta
      Type => [R[LDP+'BasicContainer'], R[SIOC+'Thread']], RDFs+'member' => m.keys.map(&:R)}
    v = r.q['view'] ||= 'force'  # visualize references
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
    r[:Response]['ETag'] = [(View[v] && v), m.keys.sort, r.format].h
    e.condResponse ->{Render[r.format][m,r]}}

  def mail; Mail.read node if f end

  def triplrMail &b
    m = mail; return unless m                        # mail
    id = m.message_id || m.resent_message_id rescue nil
    return unless id                                 # message-ID

    e = MessagePath[id]                              # message URI

    [R[SIOCt+'MailMessage'], R[SIOC+'Post']].        # SIOC types
      map{|t|yield e, Type, t}

    list = m['List-Post'].do{|l|l.decoded.sub(/^<?mailto:/,'').sub(/>$/,'').downcase}
    list && m['List-Id'].do{|name|
      name = name.decoded
      group = AddrPath[list]                         # list URI
      yield group, Type, R[FOAF+'Group']             # list class
      yield group, SIOC+'name',name.gsub(/[<>&]/,'') # list name
      yield group, SIOC+'has_container', group.R.parentURI.descend}

    m.from.do{|f|                                    # any authors?
      f.justArray.map{|f|                            # each author
        f = f.to_utf8.downcase        # author address
        creator = AddrPath[f]         # author URI
        yield e, Creator, R[creator]  # message -> author
                                      # reply target:
        r2 = list ||                   # List
             m.reply_to.do{|t|t[0]} || # Reply-To
             f                         # Creator
        yield e, SIOC+'reply_to',     # reply URI
        R[URI.escape("mailto:#{r2}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{m.subject}&")+'#reply']}}

    m[:from].addrs.head.do{|a|
      author = AddrPath[a.address]         # author URI
      yield author, Type, R[FOAF+'Person']
      yield author, SIOC+'name', (a.display_name || a.name)
      yield author, SIOC+'has_container', author.R.parentURI.descend
    }

    if m.date
      date = m.date.to_time
      yield e, Date, date.utc.iso8601 
      yield e, Stat+'mtime', date.to_i
    end

    yield e, Stat+'size', size

    m.subject.do{|s| # subject
      s = s.to_utf8.hrefs
      yield e, Label, s
      yield e, Title, s}

    yield e, SIOC+'has_discussion', R['/thread/'+id] # thread

    %w{to cc bcc}.map{|to|                      # reciever fields
     m.send(to).do{|to|                         # has field?
      to.justArray.map{|to|                     # each recipient
       to.do{|to|                               # non-nil?
        yield e, To, AddrPath[to.to_utf8].R}}}} # recipient URI

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
      H({_: :pre, class: :mail,
          c: p.decoded.to_utf8.gsub(/^(\s*>)+\n/,"").lines.to_a.map{|l| # nuke empty quotes
           if qp = l.match(/^(\s*>)+/) # quote
             {_: :span, class: :q, depth: qp[0].scan(/>/).size, c: l.hrefs}
           else
             l.hrefs
           end }})}
    
    attache = -> { e.R.a('.attache').mk }   # filesystem container for attachments & parts

    htmlCount = 0
    htmlFiles.map{|p| # HTML content
      html = attache[].child "page#{htmlCount}.html"  # name
      yield e, DC+'hasFormat', html                   # message -> HTML resource
      html.w p.decoded if !html.e                     # write content
      htmlCount += 1 }

    parts.select{|p|p.mime_type=='message/rfc822'}.map{|m| # recursive mail-container (digests + forwards)
      f = attache[].child 'msg.' + rand.to_s.h
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
    triplrCacheJSON :triplrMail, @r.do{|r|r['SERVER_NAME']}, [SIOC+'reply_of'], IndexMail, &f
  end

  IndexMail = ->doc,graph,host {
    graph.map{|u,r|
      addresses = []
      r[Creator].do{|from|addresses.concat from}
      r[To].do{|to|       addresses.concat to}
      r[Date].do{|date|
        r[Title].do{|title|
          name = title[0].gsub(/\W+/,' ').strip
          month = date[0][0..7].gsub '-','/'
          addresses.map{|address|
            container = address.R.dirname + '/' + month
            target = R[container + name + '.e']
            target = R[container + name + rand.to_s.h[0..2] + '.e'] if target.e
            doc.ln target }}}}}

  View['unread'] = -> d,e {
    [View['threads'][d,e], {_: :style, c: "\n.thread:visited {background-color:#222}\n"}]}

  View['threads'] = -> d,env {
    posts = d.resourcesOfType SIOCt+'MailMessage'

    weight = {}
    posts.map{|p| p[To].justArray.map(&:maybeURI).map{|a|
        weight[a] ||= 0
        weight[a] += 1}}

    threads = posts.group_by{|r|
      r[Title].do{|t|t[0].sub(/\b[rR][eE]: /,'')}}

    groups = threads.group_by{|_,posts|
      score = {}
      posts.map{|post|
        post[To].justArray.map(&:maybeURI).map{|a|
          score[a] ||= 0
          score[a] += weight[a] || 1}}
      score.invert.max[1]}

    [H.css('/css/threads',true),
     groups.map{|group,threads|
      {_: :p, c: {class: :posts, style: 'background-color:' + cs,
        c: [group.do{|g|{_: :a, c: g.R.fragment, href: g}},
             threads.sort_by{|t,m| 0-m.size}.map{|title,msgs| # each thread
               size = title.to_s.size
               scale = if msgs.size > 5 || size < 16
                         1.25
                       elsif size < 24
                         1.15
                       else
                         1.05
                       end
               maker = if (c = msgs.size) > 2
                         [' ',{_: :a, href: '/thread/'+msgs[0].R.basename, c: c, class: :count}]
                       else
                         msgs.map{|s|
                   s[Creator].justArray.select(&:maybeURI).map{|cr|
                     [' ',{_: :a, href: s.uri, class: :sender, c: cr.R.fragment}]}}
                       end
               name = {_: :a, class: 'thread',
                 href: '/thread/'+msgs[0].R.basename,
                 c: title.gsub(/\[(\w+)\]/,'<span>\1</span>'),
                 style: "font-size:#{scale}em"}
               {class: :post, c: [name, maker]}}
           ]}}
     },'<br clear=all>',
     {_: :a, class: :expand, href: env.uri+'?view=base', c: '▼'}]}
  
  ViewGroup[SIOCt+'MailMessage'] = View['threads']

end
