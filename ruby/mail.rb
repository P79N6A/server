# -*- coding: utf-8 -*-
#watch __FILE__
class R

  GREP_DIRS.push(/^\/address\/.\/[^\/]+\/\d{4}/)

  GET['/thread'] = -> e,r {
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of', m
    return E404[e,r] if m.empty?
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
    r[:Response]['ETag'] = [m.keys.sort, r.format].h
    e.condResponse ->{
      r[:thread] = true
      Render[r.format].do{|p|p[m,r]} ||
      m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)}}

  MessagePath = ->id{ # message-ID -> path
    id = id.gsub /[^a-zA-Z0-9\.\-@]/, ''
    '/msg/' + id.h[0..2] + '/' + id}

  GET['/msg'] = -> e,r{e.path.split('/').size < 4 ? [303, {'Location' => '/'}, []] : nil}

  AddrPath = ->address{ # address -> path
    address = address.downcase
    name = address.split('@')[0]
    alpha = address[0].match(/[<"=0-9]/) ? '_' : address[0]
    '/address/' + alpha + '/' + address + '/' + name + '#' + name}

  GET['/address'] = -> e,r {
    depth = e.path.split('/').size
    r[:ls] = true if depth == 3 # tabular view of alpha-prefix's addresses
    r.q['set'] ||= 'first-page' if depth == 4 # include first page at container root
    nil}

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
      lastEmpty = false
      yield e, Content,
      H({_: :pre, class: :mail,
         c: ["\n",
           p.decoded.to_utf8.lines.to_a.map{|l|
           l = l.chomp
           if qp = l.match(/^(\s*[>|])+/) # quote
             [{_: :span, class: :q, depth: qp[0].scan(/[>|]/).size, c: l.hrefs},"\n"]
           elsif l.match(/^((At|On)\b.*wrote:|_+|[a-zA-Z\-]+ mailing list)$/)
             [{_: :span, class: :q, depth: 1, c: l.hrefs},"\n"]
           else
             if l.empty? && lastEmpty
               nil
             else
               lastEmpty = l.empty?
               [{_: :span, class: :nq, c: l.hrefs(true)},"\n"] # show images in unquoted original content
             end
           end}]})}
    
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
    triplrCacheJSON :triplrMail, @r.do{|r|r['SERVER_NAME']}, [SIOC+'reply_of'], IndexMail, &f
  end

  ReExpr = /\b[rR][eE]: /

  Abstract[SIOCt+'MailMessage'] = -> graph, g, e {
    raw = e.q.has_key? 'raw' # keep raw-msg
    graph[e.uri].do{|dir|dir.delete(LDP+'contains')} unless raw # hide fs-meta
    if e.format == 'text/html'
      listURI = e.q.merge({'group' => 'rdf:type', 'sort' => 'dc:date'}).qs
      fullURI = e.q.merge({'raw' => 'raw'}).qs
      size = g.keys.size
      graph[listURI] = {'uri' => listURI, Type => R[Container], Label => '≡'} if !e.q.has_key?('group') && size > 12
      graph[fullURI] = {'uri' => fullURI, Type => R[Container], Label => '&darr;'} if !raw && size < 24
    end
    e.q['sort'] ||= Size # weighting uses standard size-predicate
    group = (e.q['group']||To).expand # GROUP BY
    # Pass 1. statistics
    threads = {}
    weight = {}
    g.map{|u,p|
      graph.delete u unless raw
      p[Title].do{|t|
        title = t[0].sub ReExpr, ''
        threads[title] ||= p
        threads[title][Size] ||= 0
        threads[title][Size]  += 1 }
      p[Creator].justArray.map(&:maybeURI).map{|a| graph.delete a }
      p[To].justArray.map(&:maybeURI).map{|a|
        weight[a] ||= 0
        weight[a] += 1
        graph.delete a}}
    # Pass 2. cluster
    threads.map{|title,post|
      post[group].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # heaviest address wins
        dir = a.R.dir
        container = dir.uri.t # container
        item = {'uri' => '/thread/' + post.R.basename, Title => title.noHTML, Size => post[Size]} # thread
        graph[item.uri] ||= {'uri' => item.uri, Label => item[Title]} if e.format != 'text/html' # add RDF labels
        post[Date].justArray[0].do{|date| item[Date] = date[8..-1]}
        graph[container] ||= {'uri' => container, Type => R[Container], Label => a.R.fragment}
        graph[container][LDP+'contains'] ||= []
        graph[container][LDP+'contains'].push item }}}

  ViewGroup[SIOCt+'MailMessage'] = -> d,e {
    colors = {}
    titles = {}
    q = e.q
    big = d.keys.size > 8
    noquote = q.has_key?('noquote') || big

    if noquote # toggle quoted-content
      q.delete 'noquote'
      d.map{|u,r|
        r[Content] = r[Content].justArray.map{|c|
          c.lines.map{|l|l.match(/^<span class='q'/) ? "" : l}.join}}
    else
      q['noquote'] = ''
    end

    arcs = []
    d.values.map{|s| # collect direct-reference arcs
      s[SIOC+'has_parent'].justArray.map{|o|
        arc = {source: s.uri, target: o.uri}
        author = s[Creator][0].R.fragment
        arc[:sourceName] = author unless colors[author] # show each name once
        arc[:sourceColor] = colors[author] ||= cs
        d[o.uri].do{|o| # target exists in loaded graph
          author = o[Creator][0].R.fragment
          arc[:targetName] = author unless colors[author]
          arc[:targetColor] = colors[author] ||= cs}
        arcs.push arc
      }}

    [H.css('/css/mail',true),
     {_: :style,
      c: colors.map{|name,c| "a[name=\"#{name}\"] {color: #{c}}\n"}},
     ({_: :a, href: q.qs, c: noquote ? '&#x27eb;' : '&#x27ea;', title: "hide quotes", class: :noquote} if !big),
     d.resources(e).reverse.map{|r| # show message
       [{class: :mail, id: r.uri,
         c: [
          r[Title].do{|t|
            title = t[0].sub ReExpr, ''
            if titles[title] # only shop topic if changed
              nil
            else
              titles[title] = true
              [{_: :a, class: :title, href: r.uri, c: title},'<br>']
            end
          },
          r[Creator].do{|c|
            author = c[0].R.fragment
            {_: :a, name: author, href: c[0].R.dirname, c: author}}, ' &rarr; ',
          r[SIOC+'has_parent'].do{|ps|
            ps.map{|p| # replied-to messages
              d[p.uri].do{|r| # target msg
                author = r[Creator][0].R.fragment
                {_: :a, name: author, href: '#'+p.uri, c: author}} ||
              {_: :a, class: :msg, href: p.uri, c: '&#9993;'}
            }.intersperse(' ')}, ' ',
          r[To].justArray.map{|o|
            {_: :a, class: :to, href: o.R.dirname, c: o.R.fragment} unless colors[o.R.fragment]}.intersperse(' '), ' ',
          r[SIOC+'reply_to'].do{|c|
            [{_: :a, class: :create, href: c[0].uri, c: ['&#x270e;','&#x270f;','&#x2710;'][rand(3)]},' ']},
          r[Date].do{|d|
            {_: :a, class: :ts, href: r.uri, c: d[0].sub('T',' ')}},
          r[SIOC+'has_discussion'].do{|d|
            {_: :a, class: :discussion, href: d[0].uri + '#' + r.uri, c: '≡'} unless e[:thread]},
          '<br>', r[Content],
          [DC+'hasFormat', SIOC+'attachment'].map{|p|
            r[p].justArray.map{|o|
              {_: :a, class: :attached, href: o.uri, c: o.R.basename}}}]},'<br>']},
     H.js('/js/d3.v3.min'), {_: :script, c: "var links = #{arcs.to_json};"},
     H.js('/js/mail',true)]}

end
