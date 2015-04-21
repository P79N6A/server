# -*- coding: utf-8 -*-
#watch __FILE__
class R

  GREP_DIRS.push(/^\/address\//) # allow grep in email

  MessagePath = -> id{
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

  AddrPath = ->address{ # email-address -> /path
    address = address.downcase
    person, domainname = address.split '@'
    dname = domainname.split('.').reverse
    tld = dname[0]
    domain = dname[1]
    ['', 'address', tld, domain[0], domain, *dname[2..-1], person,''].join('/') + person + '#' + person}

  GET['/thread'] = -> e,r {
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of','sioc:reply_of', m
    return E404[e,r] if m.empty?
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
    r[:Response]['ETag'] = [m.keys.sort, r.format].h
    e.condResponse ->{
      r[:thread] = true
      r[:title] = m.values.find{|r|r.class==Hash&&r[Title]}[Title][0].sub ReExpr, ''
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

    [R[SIOCt+'MailMessage'], R[SIOC+'Post']].        # SIOC types
      map{|t|yield e, Type, t}

    list = m['List-Post'].do{|l|l.decoded.sub(/.*?<?mailto:/,'').sub(/>$/,'').downcase} # list address
    list && list.match(/@/) && m['List-Id'].do{|name|
      name = name.decoded
      group = AddrPath[list]                    # list URI
      yield group, Type, R[SIOC+'Usergroup']    # list is a Group
      yield group, Label, name.gsub(/[<>&]/,'') # list name
      yield group, SIOC+'has_container', group.R.parentURI.descend + '?set=page'}

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

    m[:from].addrs.head.do{|a|
      author = AddrPath[a.address]         # author URI
      yield author, Type, R[FOAF+'Person']
      yield author, Label, (a.display_name || a.name)
      yield author, SIOC+'has_container', author.R.parentURI.descend + '?set=page'
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

    parts.select{|p| (!p.mime_type || p.mime_type=='text/plain') &&
      Mail::Encodings.defined?(p.body.encoding)      # decodable?
    }.map{|p|
      yield e, Content, H(p.decoded.to_utf8.lines.to_a.map{|l|
        l = l.chomp
        [if qp = l.match(/^((\s*[>|]\s*)+)(.*)/) # quoted
         depth = (qp[1].scan /[>|]/).size
         {class: :q, depth: depth, c: [{_: :span, c: '&gt; '*depth}, qp[3].gsub('@','.').hrefs]}
        elsif l.match(/^((At|On)\b.*wrote:|_+|[a-zA-Z\-]+ mailing list)$/)
          {class: :q, depth: 0, c: l.gsub('@','.').hrefs}
        else
          [l.hrefs(true), "<br/>"]
        end,"\n"]})}

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
  rescue Exception => x
    puts ["MAILERROR",uri,x,x.backtrace[0..2]].join(' ')
  end

  IndexMail = ->doc,graph,host { # link to address-containers
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
            doc.ln target }}}}}

  def triplrMailMessage &f
    triplrStoreJSON :triplrMail, @r.do{|r|r.host}, [SIOC+'reply_of'], IndexMail, &f
  end

  ReExpr = /\b[rR][eE]: /

  Abstract[SIOCt+'MailMessage'] = -> graph, g, e {
    graph.delete e.uri
    bodies = e.q.has_key? 'bodies'
    rdf = e.format != 'text/html'
    e.q['sort'] ||= Size
    group = (e.q['group']||To).expand
    size = g.keys.size
    threads = {}
    authors = {}
    clusters = []
    weight = {}

    # original container
    graph[e.uri] = {
      'uri' => e.uri, Label => e.R.basename,
      Type => R[Container],
      SIOC+'has_container' => e.R.parentURI,
    }

    # links to alternate container-filterings
    if !bodies && size < 24 # unabbreviated view
      fullURI = e.q.merge({'bodies' => ''}).qs
      graph[fullURI] = {'uri' => fullURI, Type => R[Container], Label => '↓'}
    end
    if !rdf && !e.q.has_key?('group') # list view
      listURI = e.q.merge({'group' => 'rdf:type', 'sort' => 'dc:date', 'reverse' => ''}).qs
      graph[listURI] = {'uri' => listURI, Type => R[Container], Label => '≡'}
    end

    g.map{|u,p| # statistics + prune pass
      graph.delete u unless bodies # hide full-message
      p[DC+'source'].justArray.map{|s| # hide originating-file metadata
        graph.delete s.uri}
      p[Title].do{|t| # title
        title = t[0].sub ReExpr, '' # strip reply-prefix
        unless threads[title] # init thread
          p[Size] = 0         # member-count
          threads[title] = p  # thread data
        end
        threads[title][Size] += 1 } # count occurrence
      p[Creator].justArray.map(&:maybeURI).map{|a|
        authors[a] ||= 0
        authors[a] += 1 # count authoring
        graph.delete a } # hide author-description
      p[To].justArray.map(&:maybeURI).map{|a|
        weight[a] ||= 0
        weight[a] += 1   # count recipient-occurrence
        graph.delete a}} # hide recipient-description

    threads.map{|title,post| # cluster pass
      post[group].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # heaviest address wins
        container = a.R.dir.uri.t # container URI
        item = {'uri' => '/thread/' + URI.escape(post[DC+'identifier'][0]), Date => post[Date],
                Label => title, Size => post[Size], Type => R[SIOC+'Thread']} # thread resource

        unless graph[container] # init cluster-container
          clusters.push container
          graph[container] = {'uri' => container, Type => R[Container], LDP+'contains' => [], Label => a.R.fragment}
        end
        graph[item.uri] ||= item if rdf # add thread to RDF graph
        graph[container][LDP+'contains'].push item }} # container -> thread link

    graph['#author'] = {'uri' => '#author', Type => R[Container],
                         LDP+'contains' => authors.map{|a,size| size > 2 ? {'uri' => a, Size => size} : nil}}

    clusters.map{|container| # count cluster-sizes
      graph[container][Size] = graph[container][LDP+'contains'].
                               justArray.inject(0){|sum,val| sum += (val[Size]||0)}}}

end
