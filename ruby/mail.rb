# -*- coding: utf-8 -*-
#watch __FILE__
class R

  GREP_DIRS.push(/^\/address\/.\/[^\/]+\/\d{4}/)

  GET['/mid'] = -> e,r{R[MessagePath[e.basename]].setEnv(r).response} # message-ID lookup
  GET['/msg'] = -> e,r{e.path=='/msg/' ? E404[e,r] : nil} # hide top-level msg-dir
  GET['/address'] = -> e,r {
    case e.path.split('/').size
    when 3
      r[:Filter] = :addrContainers
    when 4
      r.q['set'] ||= 'first-page'
    end
    nil}

  GET['/thread'] = -> e,r {
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of', m
    return E404[e,r] if m.empty?
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
    r[:Response]['ETag'] = [m.keys.sort, r.format].h
    e.condResponse ->{
      Filter[:minimalMessage][m,r] if r.q.has_key?('noquote'); r[:noquote] = true
      Render[r.format].do{|p|p[m,r]} || m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)}}

  MessagePath = ->id{ # message-ID -> path
    id = id.gsub /[^a-zA-Z0-9\.\-@]/, ''
    '/msg/' + id.h[0..2] + '/' + id}

  AddrPath = ->address{ # address -> path
    address = address.downcase
    name = address.split('@')[0]
    alpha = address[0].match(/[<"=0-9]/) ? '_' : address[0]
    '/address/' + alpha + '/' + address + '/' + name + '#' + name}

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
    list && m['List-Id'].do{|name|
      name = name.decoded
      group = AddrPath[list]                         # list URI
      yield group, Type, R[SIOC+'Usergroup']         # list class
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
    end

    m.subject.do{|s| # subject
      s = s.to_utf8
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
           elsif l.match(/^(At|On)\b.*wrote:$/)
             {_: :span, class: :q, depth: 1, c: l.hrefs}
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
  rescue Exception => x
    puts ["WARNING",uri,x,x.backtrace[0..2]].join(' ')
  end

  def triplrMailMessage &f
    triplrCacheJSON :triplrMail, @r.do{|r|r['SERVER_NAME']}, [SIOC+'reply_of'], IndexMail, &f
  end

  Filter[:minimalMessage] = -> g,e { # trim the fat off a message
    g.map{|u,r|
      [DC+'identifier',DC+'hasFormat',DC+'source',
       SIOC+'attachment',
       SIOC+'reply_of',
       SIOC+'reply_to',
       SIOC+'has_discussion',
       Label, To].map{|p| r.delete p}
      r[Content] = r[Content].justArray.map{|content|
        c = Nokogiri::HTML.fragment content
        c.css('span.q').remove
        R.trimLines c.to_xhtml.gsub /\n\n\n+/, "\n\n" }}}

  Filter[:addrContainers] = -> graph,e { # group address-containers by domain-name
    e.q['sort'] = 'uri'
    g = {}
    graph.delete e.uri
    graph.map{|u,r|
      parts = r.R.basename.split '@'
      if parts.size==2
        graph.delete u
        domain = '//' + parts[1]
        r[Title] = parts[0]
        r.delete Stat+'size'
        container = {'uri' => domain, Label => parts[1].sub(/\.(com|edu|net|org)$/,''), Type => R[Container], LDP+'contains' => []}
        g[domain] ||= container
        g[domain][LDP+'contains'].push r
      end}
    graph.merge! g }

  IndexMail = ->doc,graph,host { # link message to address containers
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

  Abstract[SIOCt+'MailMessage'] = -> graph, g, e {
    threads = {}
    weight = {}
    g.map{|u,p| # pass 1. generate statistics and prune graph
      graph.delete u
      p[DC+'source'].do{|s|graph.delete s.justArray[0].uri}
      p[Title].do{|t|
        title = t[0].sub /\b[rR][eE]: /, ''
        threads[title] ||= p
        threads[title][:size] ||= 0
        threads[title][:size]  += 1 }
      p[Creator].justArray.map(&:maybeURI).map{|a| graph.delete a }
      p[To].justArray.map(&:maybeURI).map{|a|
        weight[a] ||= 0
        weight[a] += 1
        graph.delete a}}

    if e.format == 'text/html'
      listURI = '?group=rdf:type&sort=dc:date'
      graph[listURI] = {'uri' => listURI, Type => R[Container], Label => '≡'}
    end
    rdf = e.format != 'text/html'
    group = e.q['group'].do{|t|t.expand} || To
    threads.map{|title,post| # pass 2. cluster
      post[group].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # heaviest address wins
        dir = a.R.dir
        container = dir.uri.t
        cLoc = e.q['group'] ? a.R : dir.child((post[Date].do{|d|d[0]}||Time.now.iso8601)[0..6].sub('-','/').t).uri
        item = {'uri' => '/thread/'+post.R.basename, Title => title.noHTML, Stat+'size' => post[:size]} # thread
        graph[item.uri] ||= {'uri' => item.uri, Label => item[Title]} if rdf
        post[Date].justArray[0].do{|date| item[Date] = date[8..-1]}
        graph[container] ||= {'uri' => cLoc,Type => R[Container], Label => a.R.fragment}
        graph[container][LDP+'contains'] ||= []
        graph[container][LDP+'contains'].push item }}
  }

  ViewGroup[SIOCt+'MailMessage'] = -> d,e {
    links = []
    colors = {}
    defaultType = SIOC + 'has_parent'
    linkType = e.q['link'].do{|a|a.expand} || defaultType
    noquote = e.q.has_key? 'noquote'
    d.triples{|s,p,o| # each triple
      if p == linkType && o.respond_to?(:uri) # selected arc to D3 JSON
        source = s
        target = o.uri
        link = {source: source, target: target}
        d[source].do{|s|
          s[Creator].justArray[0].do{|l|
            l = l.R
            link[:sourceName] = l.fragment unless colors[l.uri]
            link[:sourceColor] = colors[l.uri] ||= cs
         }}
        d[target].do{|t|
          t[Creator].justArray[0].do{|l|
            l = l.R
            link[:targetName] = l.fragment unless colors[l.uri]
            link[:targetColor] = colors[l.uri] ||= cs
          }}
        links.push link
      end}

    [(H.js '//d3js.org/d3.v2'),
     {_: :script, c: "var links = #{links.to_json};"},
     H.js('/js/force',true),
     H.css('/css/force',true),
     H.css('/css/mail',true),
     (if e[:noquote]
      [{_: :a, href: noquote ? '?' : '?noquote', c: noquote ? '&gt;' : '&lt;', title: "hide quotes", class: :noquote},
       noquote ? {_: :style, c: "tr[property='uri'], tr[property='http://purl.org/dc/terms/date'] {display: none}"} : []]
      end),
     {_: :style, c: colors.map{|uri,color|
        "td.val a[href=\"#{uri}\"] {color: #{color};font-weight: bold;background-color: #000}\n"}},
     ViewGroup[Resource][d,e]
    ]}

end
