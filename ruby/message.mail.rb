# coding: utf-8
class R

  ReExpr = /\b[rR][eE]: /

  MessagePath = -> id { # message Identifier -> path
    msg, domainname = id.downcase.sub(/^</,'').sub(/>.*/,'').gsub(/[^a-zA-Z0-9\.\-@]/,'').split '@'
    dname = (domainname||'').split('.').reverse
    case dname.size
    when 0
      dname.unshift 'none','nohost'
    when 1
      dname.unshift 'none'
    end
    tld = dname[0]
    domain = dname[1]
    ['', 'address', tld, domain[0], domain, *dname[2..-1], '@', id.h[0..1], msg].join('/')}

  AddrPath = ->address{ # email-address -> path
    address = address.downcase
    person, domainname = address.split '@'
    dname = (domainname||'').split('.').reverse
    tld = dname[0]
    domain = dname[1] || 'localdomain'
    ['', 'address', tld, domain[0], domain, *dname[2..-1], person,''].join('/') + person + '#' + person}

  GET['/address'] = -> e,r {e.justPath.response} # hostname unbound

  GET['/thread'] = -> e,r { # construct thread
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of','sioc:reply_of', m # recursive walk
    return E404[e,r] if m.empty?                                       # nothing found?
    r[:Response]['ETag'] = [m.keys.sort, r.format].h
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
    e.condResponse ->{
      m.values[0][Title].justArray[0].do{|t| r[:title] = t.sub ReExpr, '' }
      r[:thread] = true
      Render[r.format].do{|p|p[m,r]} ||
        m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)}}

  def mail; Mail.read node if f end

  def triplrMail &b
    m = mail; return unless m # parse
    id = m.message_id || m.resent_message_id
    unless id
      puts "missing Message-ID in #{uri}"
      id = rand.to_s.h
    end

    e = MessagePath[id]
    yield e, DC+'identifier', id
    yield e, DC+'source', self

    [R[SIOC+'MailMessage'], R[SIOC+'Post']].        # SIOC types
      map{|t|yield e, Type, t}

    list = m['List-Post'].do{|l|l.decoded.sub(/.*?<?mailto:/,'').sub(/>$/,'').downcase} # list address

    list && list.match(/@/) && m['List-Id'].do{|name| # list resource
      name = name.decoded
      group = AddrPath[list]                    # list URI
      yield group, Type, R[SIOC+'Usergroup']    # list is a Group
      yield group, Label, name.gsub(/[<>&]/,'') # list name
      yield group, SIOC+'has_container', group.R.dir
    }

    m.from.do{|f|                    # any authors?
      f.justArray.map{|f|             # each author
        f = f.to_utf8.downcase        # author address
        creator = AddrPath[f]         # author URI
        yield e, Creator, R[creator]  # message -> author
                                      # reply target:
        r2 = list ||                   # List
             m.reply_to.do{|t|t[0]} || # Reply-To
             f                         # Creator
        yield e, SIOC+'reply_to',     # reply URI
        R[URI.escape("mailto:#{r2}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{m.subject}&")+'#reply']}}

    m[:from].addrs.head.do{|a|# author resource
      author = AddrPath[a.address]
      yield author, Type, R[FOAF+'Person']
      yield author, FOAF+'name', (a.display_name || a.name)
      yield author, SIOC+'has_container', author.R.dir
    }

    if m.date
      date = m.date.to_time.utc
      yield e, Date, date.iso8601
      yield e, Mtime, date.to_i
    end

    m.subject.do{|s| # subject
      s = s.to_utf8
      yield e, Label, s
      yield e, Title, s}

    yield e, SIOC+'has_discussion', R['/thread/'+id] # thread

    %w{to cc bcc resent_to}.map{|p|           # reciever fields
      m.send(p).justArray.map{|to|            # each recipient
        yield e, To, AddrPath[to.to_utf8].R}} # recipient URI
    m['X-BeenThere'].justArray.map{|to|
      yield e, To, AddrPath[to.to_s].R }

    %w{in_reply_to references}.map{|ref|             # reference predicates
     m.send(ref).do{|rs| rs.justArray.map{|r|        # indirect-references
      yield e, SIOC+'reply_of', R[MessagePath[r]]}}} # reference URI

    m.in_reply_to.do{|r|                             # direct-reference predicate
      yield e, SIOC+'has_parent', R[MessagePath[r]]} # reference URI
    
    htmlFiles, parts = m.all_parts.push(m).partition{|p|p.mime_type=='text/html'} # parts
    
    parts.select{|p| (!p.mime_type || p.mime_type=='text/plain') && # if text &&
                 Mail::Encodings.defined?(p.body.encoding)                     #    decodable
    }.map{|p|
      body = H p.decoded.to_utf8.lines.to_a.map{|l|
        l = l.chomp
        if qp = l.match(/^((\s*[>|]\s*)+)(.*)/) # quoted line
          depth = (qp[1].scan /[>|]/).size
          if qp[3].empty?
            nil
          else
            {name: "quote#{depth}", _: :span, c: [{_: :span, c: '&gt; '*depth}, qp[3].gsub('@','.').hrefs]} # obfuscate quoted addresses
          end
        elsif l.match(/^((At|On)\b.*wrote:|_+|[a-zA-Z\-]+ mailing list)$/) # attribution line
          l.gsub('@','.').hrefs # obfuscate attributed address
        else # fresh line
          [l.hrefs(true){|p,o| # hyperlink plaintext
             yield e, p, o}] # emit discovered link(s) as RDF
        end}.compact.intersperse("<br>\n")
      yield e, Content, body}

    attache = -> {e.R.a('.attache').mk} # container for attachments & parts

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
      if p.main_type=='image'                         # image attachment?
        yield e, DC+'Image', file                     # image reference in RDF
        yield e, Content,                             # image reference in HTML
          H({_: :a, href: file.uri, c: [{_: :img, src: file.uri}, p.filename]})
      end }
  rescue Exception => x
    puts ["MAILERROR",uri,x,x.backtrace[0..2]].join(' ')
  end

  Abstract[SIOC+'MailMessage'] = -> graph, g, e {
    if graph[e.uri]
      graph[e.uri].delete LDP+'contains'
    end
    bodies = e.q.has_key? 'full'
    e[:summarized] = true unless bodies
    e.q['sort'] ||= Size
    e.q['reverse'] ||= 'reverse'
    isRDF = e.format != 'text/html'
    group = (e.q['group']||To).expand
    size = g.keys.size
    threads = {}
    clusters = []
    weight = {}

    # pass 1. prune + analyze
    g.map{|u,p|
      recipients = p[To].justArray.map &:maybeURI
      graph.delete u unless bodies # remove unsummarized
      p[DC+'source'].justArray.map{|s|graph.delete s.uri}         # provenance
      p[Creator].justArray.map(&:maybeURI).map{|a|graph.delete a} # author-description
      recipients.map{|a|graph.delete a}                           # recipient-description

      p[Title].do{|t|
        title = t[0].sub ReExpr, '' # strip prefix
        unless threads[title]
          p[Size] = 0               # member-count
          threads[title] = p        # thread
        end
        threads[title][Size] += 1}  # thread size

      recipients.map{|a|            # address weight
        weight[a] ||= 0
        weight[a] += 1}}

    # pass 2. cluster
    threads.map{|title,post|
      post[group].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # bind heaviest grouping-property value, by default should be recipient and therefore mailing-list
        container = a.R.dir.uri.t
        mid = URI.escape post[DC+'identifier'][0]

        # thread (or message)
        tags = []
        title = title.gsub(/\[[^\]]+\]/){|tag|tags.push tag[1..-2];nil}
        thread = {DC+'tag' => tags, 'uri' => '/thread/' + mid , Title => title, Image => post[Image]}

        if post[Size] > 1 # thread
          thread.update({Size => post[Size],
                         Type => R[SIOC+'Thread']})
        else # singleton post
          thread[Type] = R[SIOC+'MailMessage']
          thread[Creator] = post[Creator]
        end

        if isRDF # give post a label based on Title, messageID-derived URI considerably less informative
          graph[thread.uri] ||= {'uri' => thread.uri, Label => thread[Title]}
        end

        # create container for the cluster
        unless graph[container]
          clusters.push container
          graph[container] = {'uri' => container, Type => R[Container], LDP+'contains' => [], Label => a.R.fragment}
        end
        graph[container][LDP+'contains'].push thread }}
  }

  IndexMail = ->doc,graph,host {
    doc.roonga host
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
            target = R[container + name + ' ' + rand.to_s.h[0..2] + '.e'] if target.e
            doc.ln target }}}}} # link message to index directory

  def triplrMailMessage &f
    triplrCache :triplrMail, @r.do{|r|r.host}, [SIOC+'reply_of'], IndexMail, &f
  end

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,e {
    localPath = r.uri == r.R.path
    arc = {source: r.uri, target: r.uri, sourceLabel: r[Label], targetLabel: r[Label]}
    r[Date].do{|t|
      time = t.justArray[0].to_time
      arc[:sourceTime] = arc[:targetTime] = time
      e[:timelabel][time.iso8601[0..9]] = true
    }
    e[:arcs].push arc
    name = nil
    href = r.uri
    author = r[Creator].justArray[0].do{|c|
      authorURI = c.class==Hash || c.class==R
      name = if authorURI
               u = c.R
               u.fragment || u.basename || u.host || 'anonymous'
             else
               c.to_s
             end
      [{_: :a, name: name, c: name, href: authorURI ? (localPath ? (c.R.dir+'?set=page') : c.uri) : '#'},' ']}

    discussion = r[SIOC+'has_discussion'].justArray[0].do{|d|
      if e[:thread]
        href = r.uri + '#' + (r.R.path||'') # link to standalone msg
        nil
      else
        href = d.uri + '#' + (r.R.path||'') # link to msg in thread
        {_: :a, class: :discussion, href: href, c: '≡', title: 'show in thread'}
      end}

    # HTML
    {class: :mail, id: r.uri, href: href,
     c: [(r[Title].justArray[0].do{|t|
            {class: :title, c: {_: :a, class: :title, href: r.uri, c: CGI.escapeHTML(t)}}} unless e[:thread]),
         {class: :header,
          c: [r[To].justArray.map{|o|
                o = o.R
                {_: :a, class: :to, href: localPath ? (o.dir+'?set=page') : o.uri, c: o.fragment || o.path || o.host}}.intersperse({_: :span, class: :sep, c: ','}),
              # reply-of (direct)
              {_: :a, c: ' &larr; ',
               href: r[SIOC+'has_parent'].justArray[0].do{|p|
                 p.uri + '#' + p.uri
               }||'#'},
              author,
              r[Date].do{|d|
                [{_: :a, class: :date,
                  href: r.uri + '#' + r.uri,
                  c: d[0].sub('T',' ')},' ']},
              r[SIOC+'reply_to'].do{|c|
                [{_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'},' ']},
              discussion,
              [DC+'hasFormat', SIOC+'attachment'].map{|p|
                r[p].justArray.map{|o|
                  ['<br>', {_: :a, class: :file, href: o.uri, c: o.R.basename}]}}
             ].intersperse("\n  ")},
         r[Content].justArray.map{|c|{class: :body, c: c}},
         r[WikiText].do{|c|{class: :body, c: Render[WikiText][c]}},'<br>'
        ]}}

end
