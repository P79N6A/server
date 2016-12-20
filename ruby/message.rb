#watch __FILE__
# coding: utf-8
class R

  ViewGroup[SIOC+'BlogPost'] =  ViewGroup[SIOC+'BoardPost'] = ViewGroup[SIOC+'MailMessage'] = -> d,re {
    e = re.env
    e[:arcs] = []
    re.q['a'] ||= (e[:thread] ? Creator : 'sioc:addressed_to')
    # find timegraph arcs
    d.values.map{|s|
      if s[SIOC+'has_parent']
        s[SIOC+'has_parent'].justArray.map{|o|
          d[o.uri].do{|t| # arc target
            sLabel = s[Creator].justArray[0].do{|c|c.R.fragment}
            tLabel = t[Creator].justArray[0].do{|c|c.R.fragment}
            e[:label][sLabel] = true
            e[:label][tLabel] = true
            source = s.uri.gsub(/[^a-zA-Z0-9]/,'')
            target = o.uri.gsub(/[^a-zA-Z0-9]/,'')
            e[:arcs].push({source: source, target: target, sourceLabel: sLabel, targetLabel: tLabel})}}
      end}

    (1..15).map{|depth| e[:label]["quote"+depth.to_s] = true}

    [([{_: :script,
        c: "var arcs = #{e[:arcs].to_json};"},
       H.js('/js/d3.min'), H.js('/js/timegraph',true),
       {class: :timegraph,c: {_: :svg}}
      ] if e[:arcs].size > 1),
     (d.values[0][Title].justArray[0].do{|t|
        title = t.sub ReExpr, ''
        {_: :h3,class: :title, c: CGI.escapeHTML(title)}} if e[:thread]),
     d.map{|uri,msg| ViewA[SIOC+'BoardPost'][msg,re]}]}

  ViewA[SIOC+'BlogPost'] = ViewA[SIOC+'BoardPost'] = ViewA[SIOC+'MailMessage'] = -> r,re {
    localPath = r.uri == r.R.path
    navigateHeaders = r.R.path == re.path
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
      [{_: :a, class: :user, name: name, c: name, href: authorURI ? (localPath ? c.R.dir : c.uri) : '#'}.update(navigateHeaders ? {id: re.selector} : {}),' ']}

    discussionURI = r[SIOC+'has_discussion'].justArray[0].do{|d|d.uri+'#'+r.R.hierPart}

    # HTML
    [{class: :mail,
     c: [[(r[Title].justArray[0].do{|t|
             {_: :a, class: :title, href: discussionURI || r.uri, c: CGI.escapeHTML(t.to_s)}.update(navigateHeaders ? {id: re.selector} : {})} unless re.env[:thread]),
          r[To].justArray.map{|o|
            o = o.R
            {_: :a, class: :to, href: localPath ? o.dir : o.uri, c: o.fragment || o.path || o.host}.update(navigateHeaders ? {id: re.selector} : {})}.intersperse({_: :span, class: :sep, c: ','}),
          author,
          r[Date].do{|d|[{_: :a, class: :date, href: r.uri, c: d[0].sub('T',' ')},' ']},
          r[SIOC+'reply_to'].do{|c|
            [{_: :a, class: :pencil, title: :reply, href: CGI.escapeHTML(c.justArray[0].maybeURI||'#'), c: 'reply'}.update(navigateHeaders ? {id: re.selector} : {}),' ']},
         ].intersperse("\n"),"<br>",
         r[Content],
         [DC+'hasFormat', SIOC+'attachment'].map{|p| # property
           r[p].justArray.map{|o| # each attachment object
             ['<br>',
              {_: :a, id: re.selector, class: :file, href: o.uri, c: o.R.basename}]}},
        ]}.update(navigateHeaders ? {} : {id: r.uri.gsub(/[^a-zA-Z0-9]/,''), href: href}),
    ]}

  Abstract[SIOC+'InstantMessage'] = -> graph, msgs, env {
    ch = env.q['ch']
    msgs.map{|id,msg| # group into channels, show images on all channels, content on selected channel
      chan = msg[SIOC+'channel'].justArray[0]
      chansel = {'ch' => chan}.qs
      graph[chansel] ||= {'uri' => chansel, Title => chan, Type => R[Resource]}
      graph[chansel][Image] ||= []
      graph[chansel][Image].concat(msg[Image]||[])
      graph.delete id unless ch == chan
    }
  }
  

=begin perl

formats = {
  "fe-common/core" = {
    pubmsg = "{pubmsgnick $2 {pubnick \00311$[-9]0%n}}$1";
    pubmsg_channel = "{pubmsgnick $3 {pubnick \00311$[-9]0}%n%m({msgchannel $1})%n}$2";
  };
  "fe-common/irc" = {
    action_public = "{pubaction \00307$[-9]0 %n}$1";
    action_public_channel = "{pubaction \00307$[-9]0 %m({msgchannel $1})%n}$2";
  };
};

=end
  def triplrIRC &f
    doc = uri.gsub '#','%23'
    linenum = -1
    day = dirname.match(/\/(\d{4}\/\d{2}\/\d{2})/)[1].gsub('/','-')
    channel = bare
    source = doc.R
    r.lines.map{|l|
      l.scan(/(\d\d):(\d\d) <[\s@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = doc + '#' + (linenum += 1).to_s
        yield s, Date,day+'T'+m[0]+':'+m[1]+':00'
        yield s, SIOC+'channel', channel
        yield s, Creator, m[2]
        yield s, Label, m[2]
        yield s, Content, m[3].hrefs{|p, o| yield s, p, o}
        yield s, Type, R[SIOC+'InstantMessage']
        yield s, DC+'source', source
      }
    }
  end

  def triplrTwitter
    base = 'https://twitter.com'
    nokogiri.css('div.tweet > div.content').map{|t|
      s = base + t.css('.js-permalink').attr('href') # subject URI
      yield s, Type, R[SIOC+'MicroblogPost']
      yield s, SIOC+'channel', 'twitter'
      yield s, Creator, R(base+'/'+t.css('.username b')[0].inner_text)

      yield s, Label, t.css('.fullname')[0].inner_text
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a| # bind hostname to paths
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end
  def tw g
    node.readlines.shuffle.each_slice(22){|s|
      u = 'https://twitter.com/search?f=realtime&q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join
      u.R.twGET g}
  end

  def twGET g; triplrCache :triplrTwitter, g, nil, IndexFeedJSON end

  Abstract[SIOC+'MailMessage'] = -> graph, g, e {
    threads = {}
    weight = {}
    bodies = e.q.has_key? 'full'
    e.env[:summarized] = true unless bodies || g.keys.size > 42
    groupBy = (e.q['group']||To).expand

    # pass 1. statistics
    g.map{|u,p|
      recipients = p[To].justArray.map &:maybeURI
      graph.delete u unless bodies # hide unsummarized, unless full-bodies requested
      p[Creator].justArray.map(&:maybeURI).map{|a|graph.delete a} # hide author resource
      recipients.map{|a|graph.delete a}                           # hide recipient resource
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
      post[groupBy].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|group|
        mid = URI.escape post[DC+'identifier'][0]
        tags = []
        title = title.gsub(/\[[^\]]+\]/){|tag|tags.push tag[1..-2];nil}
        tags = [group] if tags.empty?
        thread = {Type => R[SIOC+'Thread'], 'uri' => '/thread/' + mid , Title => title, Date => post[Date], Label => tags, Image => post[Image]}
        thread.update({Size => post[Size]}) if post[Size] > 1
        graph[thread.uri] = thread }}}

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

  GET['/address'] = -> e {e.justPath.response} # hostname unbound

  GET['/thread'] = -> e { # construct thread
    m = {}
    R[MessagePath[e.basename]].walk SIOC+'reply_of','sioc:reply_of', m # recursive walk
    return e.notfound if m.empty?                                      # nothing found
    e.env[:Response]['ETag'] = [m.keys.sort, e.format].h
    e.env[:Response]['Content-Type'] = e.format + '; charset=UTF-8'
    e.condResponse ->{
      m.values[0][Title].justArray[0].do{|t| e.env[:title] = t.sub ReExpr, '' }
      e.env[:thread] = true
      Render[e.format].do{|p|p[m,e]} ||
        m.toRDF.dump(RDF::Writer.for(:content_type => e.format).to_sym, :standard_prefixes => true, :prefixes => Prefixes)}}

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
    yield e, DC+'source', self # pointer to origin-file

    [R[SIOC+'MailMessage'], R[SIOC+'Post']].        # SIOC types
      map{|t|yield e, Type, t}

    list = m['List-Post'].do{|l|l.decoded.sub(/.*?<?mailto:/,'').sub(/>$/,'').downcase} # list address

    list && list.match(/@/) && m['List-Id'].do{|name| # list resource
      name = name.decoded
      group = AddrPath[list]                    # list URI
      yield group, Type, R[SIOC+'Usergroup']    # list is a Group
      yield group, Label, name.gsub(/[<>&]/,'') # list name
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
        target = URI.escape('<' + id + '>')
        yield e, SIOC+'reply_to', R["mailto:#{URI.escape r2}?References=#{target}&In-Reply-To=#{target}&subject=#{(CGI.escape m.subject).gsub('+','%20')}&"+'#reply']}} # reply-to pointer

    m[:from].addrs.head.do{|a|# author resource
      author = AddrPath[a.address]
      yield author, Type, R[FOAF+'Person']
      yield author, FOAF+'name', (a.display_name || a.name)
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
            indent = "<span name='quote#{depth}'>&gt;</span>"
            {_: :span, class: :quote, c: [indent * depth,' ', {_: :span, class: :quoted, c: qp[3].gsub('@','.').hrefs}]}
          end
        elsif l.match(/^((At|On)\b.*wrote:|_+|[a-zA-Z\-]+ mailing list)$/) # attribution line
          l.gsub('@','.').hrefs # obfuscate attributed address
        else # fresh line
          [l.hrefs{|p,o| # hyperlink plaintext
             yield e, p, o}] # emit found links as RDF
        end}.compact.intersperse("<br>\n")
      yield e, Content, body}

    attache = -> {e.R.a('.attache').mk} # container for attachments & parts

    htmlCount = 0
    htmlFiles.map{|p| # HTML content
      html = attache[].child "page#{htmlCount}.html"  # name
      yield e, DC+'hasFormat', html                   # message -> HTML resource
      html.w p.decoded  if !html.e                     # write content
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
      puts "attachment in #{uri} , #{file}"
      file.w p.body.decoded if !file.e                # write
      yield e, SIOC+'attachment', file                # message -> attached resource
      if p.main_type=='image'                         # image attachment?
        yield e, DC+'Image', file                     # image reference in RDF
        yield e, Content,                             # image reference in HTML
          H({_: :a, href: file.uri, c: [{_: :img, src: file.uri}, p.filename]})
      end }
  end

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
    triplrCache :triplrMail, host, [SIOC+'reply_of'], IndexMail, &f
  end

  def getFeed h = 'localhost' # index-context (hostname)
    store :format => :feed, :hook => IndexFeedRDF, :hostname => h, :base_uri => uri
    self
  end

  def getFeeds h='localhost'
    uris.map{|u|
      u.R.getFeed h}
    nil
  end

  def listFeeds; (nokogiri.css 'link[rel=alternate]').map{|u|R (URI uri).merge(u.attr :href)} end
  alias_method  :feeds, :listFeeds

  module Feed
    
    class Format < RDF::Format
      content_type     'application/atom+xml', :extension => :atom
      content_encoding 'utf-8'
      reader { R::Feed::Reader }
    end

    class Reader < RDF::Reader

      format Format

      def initialize(input = $stdin, options = {}, &block)
        @doc = (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read.utf8
        @base = options[:base_uri]
        if block_given?
          case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
          end
        end
        nil
      end
      
      def each_statement &fn
        dateNormalize(:massage,:mapPredicates,:rawFeedTriples){|s,p,o| # triples emitted from right-to-left in function list
          fn.call RDF::Statement.new(s.R, p.R,
                                     o.class == R ? o : (l = RDF::Literal (if p == Content
                                                                             R::StripHTML[o]
                                                                           else
                                                                             o.gsub(/<[^>]*>/,' ')
                                                                           end)
                                                         l.datatype=RDF.XMLLiteral if p == Content
                                                         l),
                                     :graph_name => s.R.docroot)}
      end

      def each_triple &block
        each_statement{|s| block.call *s.to_triple}
      end

      def massage *f
        send(*f){|s,p,o|
          # resolve URIs in content
          yield s, p, (p==Content && o.class==String) ?
          (Nokogiri::HTML.fragment o).do{|o|
            o.css('a').map{|a|
              if a.has_attribute? 'href'
                ( a.set_attribute 'href', (URI.join s, (a.attr 'href'))) rescue nil
              end}
            o.to_xhtml} : o }
      end

      def mapPredicates *f
        send(*f){|s,p,o|
          yield s,
                { Purl+'dc/elements/1.1/creator' => Creator,
                  Purl+'dc/elements/1.1/subject' => SIOC+'subject',
                  Atom+'author' => Creator,
                  RSS+'description' => Content,
                  RSS+'encoded' => Content,
                  RSS+'modules/content/encoded' => Content,
                  RSS+'modules/slash/comments' => SIOC+'num_replies',
                  Atom+'content' => Content,
                  Atom+'summary' => Content,
                  RSS+'title' => Title,
                  Atom+'title' => Title,
                }[p] || p, o
        }
      end

      def rawFeedTriples # we allow nonconformant XML, missing 's, arbitrary rss1/rss2/Atom feature-use mashup, aka real-world soup-mess

        # base elements
        reHead = /<(rdf|rss|feed)([^>]+)/i
        reXMLns = /xmlns:?([a-z]+)?=["']?([^'">\s]+)/
        reItem = %r{<(?<ns>rss:|atom:)?(?<tag>item|entry)(?<attrs>[\s][^>]*)?>(?<inner>.*?)</\k<ns>?\k<tag>>}mi
        reElement = %r{<([a-z]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi

        # node identifiers
        reRDFid = /about=["']?([^'">\s]+)/            # RDF @about
        reLink = /<link>([^<]+)/                      # <link> inner-text
        reLinkAlt = /<link[^>]+rel=["']?alternate["']?[^>]+href=["']?([^'">\s]+)/ # <link> @rel=alternate href
        reLinkRel = /<link[^>]+href=["']?([^'">\s]+)/ # <link> href
        reGUID = /<(?:gu)?id[^>]*>([^<]+)/            # <id> inner-text
        commentRe = /\/comments\//

        # media links
        reAttach = %r{<(link|enclosure|media)([^>]+)>}mi
        reSrc = /(href|url|src)=['"]?([^'">\s]+)/
        reRel = /rel=['"]?([^'">\s]+)/
        
        x = {} # XML-namespace table
        head = @doc.match(reHead)
        head && head[2] && head[2].scan(reXMLns){|m|
          prefix = m[0]
          base = m[1]
          base = base + '#' unless %w{/ #}.member? base [-1]
          x[prefix] = base}

        @doc.scan(reItem){|m|
          attrs = m[2]
          inner = m[3]

          # post identifier
          u = (attrs.do{|a|a.match(reRDFid)} ||
               inner.match(reLink) ||
               inner.match(reLinkAlt) ||
               inner.match(reLinkRel) ||
               inner.match(reGUID)).do{|s|
            s[1]}

          if u

            unless u.match /^http/ # resolve to fully-expanded URI
              u = (URI.join @base, u).to_s
            end

            resource = u.R
            if u.match commentRe
              yield u, R::SIOC+'channel', resource.path.match(commentRe).pre_match.tail
              yield u, R::Type, R[R::SIOC+'MicroblogPost']
            else
              yield u, R::To, R[resource.schemePart + resource.hostPart]
              yield u, R::Type, R[R::BlogPost]
            end

            inner.scan(reAttach){|e|
              e[1].match(reSrc).do{|url|
                rel = e[1].match reRel
                yield(u, R::Atom+rel[1], url[2].R) if rel}}

            inner.scan(reElement){|e|
              p = (x[e[0] && e[0].chop]||R::RSS) + e[1]
              if p==Atom+'id' || p==Atom+'link'
                # identifier predicates bound to subject-URI
              else
                yield u,p,e[3].extend(SniffContent).sniff.do{|o|
                  o.match(HTTP_URI) ? o.R : o }
              end
            }
          end
        }

      end
      
      def dateNormalize *f
        send(*f){|s,p,o|
          yield *({'CreationDate' => true,
                    'Date' => true,
                    RSS+'pubDate' => true,
                    Date => true,
                    Purl+'dc/elements/1.1/date' => true,
                    Atom+'published' => true,
                    Atom+'updated' => true
                  }[p] ?
                  [s,Date,Time.parse(o).utc.iso8601] : [s,p,o])}
      end

    end

    module SniffContent

      def sniff
        send (case self
              when /^\s*<\!\[CDATA/m
                :cdata
              when /</m
                :id
              else
                :html
              end)
      end

      def html
        CGI.unescapeHTML self
      end

      def cdata
        sub /^\s*<\!\[CDATA\[(.*?)\]\]>\s*$/m,'\1'
      end

    end

  end

  def triplrFeed
    base = @r.R.join uri
    RDF::Reader.open(pathPOSIX, :format => :feed, :base_uri => base){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s, o.class == R ? o : o.value}}
  end

  FeedStop = /\b(at|blog|com(ments)?|html|info|org|photo|p|post|r|status|tag|twitter|wordpress|www|1999|2005)\b/

  IndexFeedJSON = -> doc, graph, host {
    doc.roonga host
    graph.map{|u,r|
      r[Date].do{|t|
        t = t[0].gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # iso8601 to date-path, for timeline
        b = (u.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.' # clean name slug
        doc.ln R["//#{host}/#{t}#{b}e"]}} # link to timeline
    doc}

  IndexFeedRDF = -> doc, graph, host {
    doc.roonga host
    graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t|
      time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, '' # trim normalized timezones
      base = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/\W/,'..').gsub(FeedStop,'').sub(/\d{12,}/,'')+'.').gsub /\.+/,'.'
      doc.ln R["//#{host}/#{time}#{base}ttl"]}} # link

  Render['application/atom+xml'] = -> d,e {
    H(['<?xml version="1.0" encoding="utf-8"?>',
       {_: :feed,xmlns: 'http://www.w3.org/2005/Atom',
         c: [{_: :id, c: e.uri},
             {_: :title, c: "Atom feed for " + e.uri},
             {_: :link, rel: :self, href: e.uri},
             {_: :updated, c: Time.now.iso8601},
             d.map{|u,d|
               {_: :entry,
                 c: [{_: :id, c: u}, {_: :link, href: u},
                     d[Date].do{|d|   {_: :updated, c: d[0]}},
                     d[Title].do{|t|  {_: :title,   c: t}},
                     d[Creator].do{|c|{_: :author,  c: c[0]}},
                     {_: :content, type: :xhtml,
                       c: {xmlns:"http://www.w3.org/1999/xhtml",
                           c: d[Content]}}]}}]}])}

end
