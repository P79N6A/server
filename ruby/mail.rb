# -*- coding: utf-8 -*-
watch __FILE__
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
      RDFs+'member' => m.keys.map(&:R)}

    v = r.q['view'] ||= 'force'
    r[:Response]['Access-Control-Allow-Origin'] = r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*'
    r[:Response]['Access-Control-Allow-Credentials'] = 'true'
    r[:Response]['Content-Type'] = r.format + '; charset=UTF-8'
    r[:Response]['ETag'] = [(View[v] && v), m.keys.sort, r.format].h

    e.condResponse ->{Render[r.format][m, r]}}

  GREP_DIRS.push /^\/m\/[^\/]+\//

  def mail; Mail.read node if f end

  def triplrMail &b
    m = mail; return unless m                        # mail
    addr = '/address/'
    id = m.message_id || m.resent_message_id rescue nil
    return unless id                                 # message-ID

    e = MessagePath[id]                              # message URI
#   yield e, DC+'identifier', id                     # origin-domain ID

    [R[SIOCt+'MailMessage'],                         # SIOC types
     R[SIOC+'Post'],
     R[RDFs+'Resource']].                            # RDF types
      map{|t|yield e, Type, t}

    list = m['List-Post'].do{|l|l.decoded[8..-2]}    # list ID
    m['List-Id'].do{|name|
      name = name.decoded
      dir = addr + list[0] + '/' + list              # list Container
      group = dir + '#' + list                       # list URI
      yield group, Type, R[FOAF+'Group']             # list class
     (yield group, SIOC+'name',name.gsub(/[<>&]/,'') # list name
            ) unless name[1..-2] == list
      yield group, SIOC+'has_container', dir.R.descend
    } if list

    m.from.do{|f|                                    # any authors?
      f.justArray.map{|f|                            # each author
        f = f.to_utf8
        creator = addr + f[0] + '/' + f + '#' + f    # author URI
        yield e, Creator, R[creator]                 # message -> author
                                                     # reply target
        r2 = list ||                                 #  List
             m.reply_to.do{|t|t[0]} ||               #  Reply-To
             f                                       #  From
        yield e, SIOC+'reply_to',                    # reply URI
        R[URI.escape("mailto:#{r2}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{m.subject}&")+'#reply']}}

    m[:from].addrs.head.do{|a|                      # author address
      from = a.address                              # author ID
      name = a.display_name || a.name               # author name
      dir = addr + from[0] + '/' + from             # author Container
      author = dir + '#' + from                     # author URI
      yield author, Type, R[FOAF+'Person']
      yield author, SIOC+'name', name
      yield author, SIOC+'has_container', dir.R.descend
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

    %w{to cc bcc}.map{|to|                           # reciever fields
     m.send(to).do{|to|                              # has field?
      to.justArray.map{|to|                          # each recipient
       to.do{|to|                                    # non-nil? 
        to = to.to_utf8                              # UTF-8
        yield e, To, R[addr+to[0]+'/'+to+'#'+to]}}}} # recipient URI

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
           c: p.decoded.to_utf8.hrefs.gsub(/^\s*(&gt;)(&gt;|\s)*\n/,"").lines.to_a.map{|l| # skip quoted empty lines
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

  def mailUID
    fragment.do{|f| f.split('@')[0] }
  end

  def R.mailName l
    if l.respond_to? :uri
      l.uri.split(/[\/#]/)[-1].split('@')[0]
    else
      l.to_s
    end
  end

  IndexMail = ->doc, graph, host {
    graph.map{|u,r| a = []
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
      r[Title].do{|t|t[0].
        gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>').
        sub(/\b[rR][eE]: /,'')}}

    groups = threads.group_by{|_,posts|
      score = {}
      posts.map{|post|
        post[To].justArray.map(&:maybeURI).map{|a|
          score[a] ||= 0
          score[a] += weight[a] || 1}}
      score.invert.max[1]}

    [View[HTTP+'Response'][d,env], (H.css '/css/threads', true),'<br clear=all>',
     groups.map{|group,threads| # each group
       color = cs
       [group.do{|g|{class: :group, c: {_: :a, :class => :to, style: "color: #{color}; border-color: #{color}", c: g.R.mailUID, href: g}}},
        {class: :posts, style: 'background-color:' + color,
          c: threads.sort_by{|t,m| 0-m.size}.map{|title,msgs| # each thread
            size = title.to_s.unHTML.size
            scale = if msgs.size > 5 || size < 16
                      1.16
                    elsif size < 24
                      1.08
                    else
                      1
                    end
            maker = if (c = msgs.size) > 2
                      {_: :a, href: '/thread/'+msgs[0].R.basename, c: c, class: :count}
                    else
                      msgs.map{|s|
                        s[Creator].justArray.select(&:maybeURI).map{|cr|
                     [' ',{_: :a, href: '/thread/'+s.R.basename+'#'+s.uri, class: :sender, style: "color: #{color}",c: cr.R.mailUID}]}}
                    end
            name = {_: :a, class: 'thread', href: '/thread/'+msgs[0].R.basename, c: title, style: "font-size:#{scale}em"}
            {class: :post, c: [name, maker]}}}]}]}

end
