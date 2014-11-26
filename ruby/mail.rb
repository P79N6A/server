# -*- coding: utf-8 -*-
#watch __FILE__
class R

  MessagePath = ->id{ # message-ID -> path
    id = id.gsub /[^a-zA-Z0-9\.\-@]/, ''
    '/msg/' + id.h[0..2] + '/' + id}

  AddrPath = ->address{ # address -> path
    address = address.downcase
    name = address.split('@')[0]
    alpha = address[0].match(/[<"=0-9]/) ? '_' : address[0]
    '/address/' + alpha + '/' + address + '/' + name + '#' + name}

  GET['/mid'] = -> e,r{R[MessagePath[e.basename]].setEnv(r).response} # message-ID lookup
  GET['/msg'] = -> e,r{e.path=='/msg/' ? E404[e,r] : nil}
  
  GET['/thread'] = -> e,r {
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of', m
    return E404[e,r] if m.empty?
    v = r.q['view'] ||= 'force'  # visualize references
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
    r[:Response]['ETag'] = [(View[v] && v), m.keys.sort, r.format].h
    e.condResponse ->{
      Render[r.format].do{|p|p[m,r]} || m.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)}}

  def mail; Mail.read node if f end

  def triplrMail &b
    m = mail; return unless m                        # mail
    id = m.message_id || m.resent_message_id
    unless id
      puts "missing Message-ID in #{uri}"
      id = rand.to_s.h
    end

    e = MessagePath[id]                              # message-ID -> URI

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

  ViewA[SIOCt+'MailMessage'] = -> r,e {[ViewA['default'][r,e], H.once(e, 'mail', H.css('/css/mail',true))]} # add quote-styling CSS
  View['unquoted'] = -> g,e {[{_: :style, c: "
body table.html {margin-bottom: 0}
tr[property] {display: none}
tr[property=uri],tr[property=\"http://rdfs.org/sioc/ns#content\"] {display: inline}
tr[property=\"http://rdfs.org/sioc/ns#content\"] span.q {display: none}
"},View['force'][g,e]]}

  IndexMail = ->doc,graph,host { # link message to address index(es)
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
    ls = e.q.has_key? 'ls'
    e.q['sort'] = 'dc:date' if ls
    g.values.map{|p| # inspect message
      p[Title].do{|t|
        title = t[0].sub /\b[rR][eE]: /, ''
        threads[title] ||= p
        threads[title][:size] ||= 0
        threads[title][:size]  += 1 }
      p[Creator].justArray.map(&:maybeURI).map{|a| graph.delete a }
      p[To].justArray.map(&:maybeURI).map{|a| weight[a] ||= 0; weight[a] += 1;graph.delete a} # weigh target-addresses
    }
    threads.map{|title,post| # inspect posts
      post[To].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|a| # put in heaviest address-cluster
        addr = a.R; dir = addr.dir
        container = ls ?  '' : dir.uri
        item = {'uri' => '/thread/'+post.R.basename, Title => title.noHTML, Stat+'size' => post[:size]} # thread
        post[Date].justArray[0].do{|date| item[Date] = date[8..-1]}
        graph[container] ||= {'uri' => dir.child((post[Date].do{|d|d[0]}||Time.now.iso8601)[0..6].sub('-','/')),Type => R[Container], Label => addr.fragment}
        graph[container][LDP+'contains'] ||= []
        graph[container][LDP+'contains'].push item
      }}
    unless ls
      graph[''] ||= {}
      graph[''][LDP+'contains'] ||= []
      graph[''][LDP+'contains'].push({'uri' => '?ls', Title => '☰', Stat+'size' => threads.size})
    end
    e[:filemeta] = false
  }

end
