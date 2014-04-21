# -*- coding: utf-8 -*-
#watch __FILE__
class R

  MessagePath = ->id{
    id = id.gsub /[^a-zA-Z0-9\.\-@]/, ''
    '/msg/' + id.h[0..2] + '/' + id}

  GET['/mid'] = -> e,r{R[MessagePath[e.base]].setEnv(r).response}

  GET['/thread'] = -> e, r {
    m = {'#' => {'uri' => '#', Type => R[HTTP+'Response']}}
    R[MessagePath[e.basename]].walk SIOC+'reply_of', m
    return E404[e,r] if m.empty?
    return [406,{},[]] unless Render[r.format]
    v = r.q['view'] ||= "timegraph"
    r[:Response]['ETag'] = [(View[v] && v), m.keys.sort, r.format].h
    r[:Response]['Content-Type'] = r.format
    e.condResponse ->{Render[r.format][m, r]}}

  GET['/m'] = -> e,r{ # range over posts when descended into author 
    if m = e.justPath.uri.match(/^\/m\/([^\/]+)\/$/)
      r.q['set']  ||= 'depth'
      r.q['view'] ||= 'threads'
      e.response
    else
      false
    end}

  GREP_DIRS.push /^\/m\/[^\/]+\//

  def mail; Mail.read node if f end

  def triplrMail
    m = mail          ; return unless m              # mail
    id = m.message_id ; return unless id             # message-ID
    e = MessagePath[id]                              # message URI

    yield e, DC+'identifier', id                     # origin-domain ID

    [R[SIOCt+'MailMessage'],                         # SIOC types
     R[SIOC+'Post']].map{|t|yield e, Type, t}        # RDF types

    m.from.do{|f|                                    # any authors?
      f.justArray.map{|f|                            # each author
        f = f.to_utf8
        creator = '/m/'+f+'#'+f                        # author URI
        yield e, Creator, R[creator]                   # message -> author
                                                       # reply target selection:
        r2 = m['List-Post'].do{|lp|lp.decoded[8..-2]} || # List-Post
             m.reply_to.do{|t|t[0]} ||                   # Reply-To
             f                                           # From
        yield e, SIOC+'reply_to',                      # reply URI
        R[URI.escape("mailto:#{r2}?References=<#{id}>&In-Reply-To=<#{id}>&Subject=#{m.subject}&")+'#reply']}}

    m[:from].addrs.head.do{|a|
      addr = a.address
      name = a.display_name || a.name
      author = '/m/'+addr+'#'+addr
      yield author, DC+'identifier', addr
      yield author, FOAF+'mbox', R['mailto:'+addr]
      yield author, SIOC+'name', name
      yield author, Type, R[FOAF+'Person']
    }

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

  def triplrMailMessage &f
    addDocsJSON :triplrMail, @r['SERVER_NAME'], [SIOC+'reply_of'], IndexMail, &f
  end

  IndexMail = ->doc, graph, host {
    graph.map{|u,r|
      a = [] # address references
      r[Creator].do{|c|a.concat c}
      r[To].do{|t|a.concat t}
      r[Date].do{|t|
        st = '/' + t[0][0..18].gsub('-','/').sub('T','.') + '.' + u.h[0..1] + '.e'
        a.map{|rel|
          doc.ln R[rel.uri.split('#')[0]+st]}}}}

  View['threads'] = -> d,env {
    posts = d.resourcesOfType SIOC+'Post'
    threads = posts.group_by{|r| # group threads
      r[Title].do{|t|t[0].sub(/^[rR][eE][^A-Za-z]./,'').gsub(/[<>]/,'_').gsub(/\[([a-z\-A-Z0-9]+)\]/,'<span class=g>\1</span>')} ||
      r[Content]}
    [{_: :table, c: threads.group_by{|r,k| # group recipients
         k[0].do{|k|k[To].do{|o|o[0].uri}}}.map{|group,threads|
         c = R.cs
         {_: :tr, c: [{_: :td,
           c: threads.map{|title,msgs| # thread
             [{_: :a, class: 'thread', style: "border-color:#{c}", href: '/thread/'+msgs[0].R.base, c: title},
              msgs.map{|s| s[Creator].select(&:maybeURI).map{|cr|
                  [' ',{_: :a, href: '/thread/'+s.R.base+'#'+s.uri,class: 'sender', style: 'background-color:'+c,
                     c: cr.R.fragment.do{|f| f.split('@')[0] } || cr.uri}]}},'<br>']}},
               group.do{|g|{_: :td, class: :group, c: {_: :a, :class => :to, style: 'background-color:'+c, c: g.R.abbr, href: g}}}]}}},
     {_: :a, id: :down, href: env['REQUEST_PATH'] + env.q.merge({'view'=>''}).qs, c: '↓'}, # to full view
     (H.css '/css/threads')]}

end
