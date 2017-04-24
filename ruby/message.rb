# coding: utf-8
class R

  def triplrIRC &f
    doc = uri.gsub '#','%23'
    linenum = -1
    # read date from strftime-path "%Y/%m/%d/%H/$net$chan.log"
    day = dirname.match /\/(\d{4}\/\d{2}\/\d{2})/
    return unless day
    day = day[1].gsub('/','-')
    channel = bare
    r.lines.map{|l|
      l.scan(/(\d\d):(\d\d) <[\s@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = doc + '#' + (linenum += 1).to_s
        yield s, Date,day+'T'+m[0]+':'+m[1]+':00'
        yield s, Creator, m[2]
        yield s, To, channel
        yield s, Content, m[3].hrefs{|p, o| yield s, p, o}
        yield s, Type, R[SIOC+'InstantMessage']
      }
    }
  rescue
    puts 'error scanning ' + uri
  end

  View[SIOC+'MarkdownContent'] = -> graph, env {
    graph.map{|uri,res| res[Content]}}

  Abstract[SIOC+'InstantMessage'] = -> graph, msgs, re {
    ch = re.q['ch']
    msgs.map{|uri,msg|
      chan = msg[To].justArray[0]
      id = {'ch' => chan}.qs
      graph[id] ||= {'uri' => id, Title => chan, Type => R[SIOC+'Discussion'], Size => 0}
      graph[id][Size] += 1
      if re.env[:grep]
        msg[Content].do{|c| # preserve content - grep filter will reduce
          graph[id][Content] ||= []
          graph[id][Content].concat c}
      end
      msg[Image].do{|images|
        graph[id][Image] ||= []
        graph[id][Image].concat images}
      msg[DC+'link'].do{|links|
        graph[id][DC+'link'] ||= []
        graph[id][DC+'link'].concat links}
      graph.delete uri unless chan==ch
    }
  }

  def triplrTwitter
    base = 'https://twitter.com'
    nokogiri.css('div.tweet > div.content').map{|t|
      s = base + t.css('.js-permalink').attr('href') # subject URI
      author = R[base+'/'+t.css('.username b')[0].inner_text]
      yield s, Type, R[SIOC+'Tweet']
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      yield s, Creator, author
     #yield author.uri, Label, t.css('.fullname')[0].inner_text
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a| # bind hostname to paths
        u = a.attr 'href'
        a.set_attribute('href',base + u) if u.match /^\//}
      yield s, Content, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end

  def tw
    node.readlines.shuffle.each_slice(22){|s|
      R['https://twitter.com/search?f=realtime&q='+s.map{|u|'from:'+u.chomp}.intersperse('+OR+').join].twGET}
  end

  def twGET
    indexStream :triplrTwitter
  end

  def triplrMailIndexer &f
    indexStream :triplrMail, &f
  end

  Abstract[SIOC+'MailMessage'] = -> graph, g, e {
    threads = {}
    weight = {}

    # pass 1. statistics
    g.map{|u,p|
      graph.delete u # drop full resource from graph
      recipients = p[To].justArray.map &:maybeURI
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
      # select heaviest recipient
      post[To].justArray.select(&:maybeURI).sort_by{|a|weight[a.uri]}[-1].do{|to|
        # thread identifier
        id = '/thread/' + URI.escape(post[DC+'identifier'][0])
        # parse labels in subject
        labels = []
        title = title.gsub(/\[[^\]]+\]/){|l|labels.push l[1..-2];nil}
        # thread resource
        thread = {Type => R[Post], To => to, 'uri' => id , Title => title, Date => post[Date], Image => post[Image], Content => e.env[:grep] ? post[Content] : []}
        thread.update({Label => labels}) unless labels.empty?
        if post[Size] > 1
          # thread aka discussion, omit author-list
          thread.update({Size => post[Size], Type => R[SIOC+'Thread']})
        else
          # single message, show author
          thread[Creator] = post[Creator]
        end
        # add thread resource to responsegraph
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

  GET['thread'] = -> e { # construct thread
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
    yield e, DC+'source', self # reference to origin-file
    yield e, Type, R[SIOC+'MailMessage']

    list = m['List-Post'].do{|l|l.decoded.sub(/.*?<?mailto:/,'').sub(/>$/,'').downcase} # list address

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

#    m[:from].do{|fr|fr.addrs.head.do{|a|yield AddrPath[a.address],Label, a.display_name||a.name}}

    if m.date
      date = m.date.to_time.utc
      yield e, Date, date.iso8601
      yield e, Mtime, date.to_i
    end

    m.subject.do{|s| yield e, Title, s.to_utf8}

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
        end}.compact.intersperse("\n")
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
        yield e, Image, file                     # image reference in RDF
        yield e, Content,                             # image reference in HTML
          H({_: :a, href: file.uri, c: [{_: :img, src: file.uri}, p.filename]})
      end }
  end

  # GET Atom/RSS feed(s) (uncached)
  def getFeeds
    uris.map &:getFeed
    self
  end
  def getFeed
    indexResource :format => :feed, :base_uri => uri
    self
  end

  # fetch Atom/RSS feed(s) (cached)
  def fetchFeeds
    uris.map &:fetchFeed
    self
  end
  def fetchFeed
    head = {} # request header
    cache = R['/cache/'+uri.h]     # cache URI
    etag = cache.child 'etag'      # cached etag URI
    priorEtag = nil                # cached etag value
    mtime = cache.child 'mtime'    # cached mtime URI
    priorMtime = nil               # cached mtime value
    body = cache.child 'body.atom' # cached body URI

    # prefer etag over mtime for version-match
    #  https://tools.ietf.org/html/rfc7232#section-3.3
    if etag.e
      priorEtag = etag.r
      head["If-None-Match"] = priorEtag unless priorEtag.empty?
    elsif mtime.e
      priorMtime = mtime.r.to_time
      head["If-Modified-Since"] = priorMtime.httpdate
    end

    begin # run conditional GET
      open(uri, head) do |response| # got a new response
        # read headers
        curEtag = response.meta['etag']
        curMtime = response.last_modified || Time.now rescue Time.now
        # write any changes to header-cache
        etag.w curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag
        mtime.w curMtime.iso8601 if curMtime != priorMtime
        # read body
        resp = response.read
        unless body.e && body.r == resp
          body.w resp # update body-cache
          ('file://'+body.pathPOSIX).R.indexResource :format => :feed, :base_uri => uri # index post(s)
        end
      end
    rescue OpenURI::HTTPError => error
      msg = error.message
      puts [uri,msg].join("\t") unless msg.match(/304/) # print unusual errors
    end
    self
  rescue Exception => e
    puts [uri, e.class, e.message, e.backtrace[0..2].join("\n")].join " "
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
                                                         l), :graph_name => s.R)}
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
                {Purl+'dc/elements/1.1/subject' => SIOC+'subject',
                 RSS+'description' => Content,
                 RSS+'encoded' => Content,
                 RSS+'modules/content/encoded' => Content,
                 RSS+'modules/slash/comments' => SIOC+'num_replies',
                 Atom+'content' => Content,
                 Atom+'summary' => Content,
                 RSS+'title' => Title,
                 Atom+'title' => Title,
                }[p]||p, o }
      end

      def rawFeedTriples # regex allowing nonconformant XML, missing ' around values, arbitrary rss1/rss2/Atom feature-use mashup

        # elements
        reHead = /<(rdf|rss|feed)([^>]+)/i
        reXMLns = /xmlns:?([a-z0-9]+)?=["']?([^'">\s]+)/
        reItem = %r{<(?<ns>rss:|atom:)?(?<tag>item|entry)(?<attrs>[\s][^>]*)?>(?<inner>.*?)</\k<ns>?\k<tag>>}mi
        reElement = %r{<([a-z0-9]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi

        # identifiers
        reRDFid = /about=["']?([^'">\s]+)/            # RDF @about
        reGUID = /<(?:gu)?id[^>]*>([^<]+)/            # <id> element innertext
        reLink = /<link>([^<]+)/                      # <link> element innertext
        reLinkCD = /<link><\!\[CDATA\[([^\]]+)/       # <link> CDATA block innertext
        reLinkAlt = /<link[^>]+rel=["']?alternate["']?[^>]+href=["']?([^'">\s]+)/ # <link> href attribute of type rel=alternate
        reLinkRel = /<link[^>]+href=["']?([^'">\s]+)/ # <link> href attribute

        # media links
        reAttach = %r{<(link|enclosure|media)([^>]+)>}mi
        reSrc = /(href|url|src)=['"]?([^'">\s]+)/
        reRel = /rel=['"]?([^'">\s]+)/

        commentRe = /\/comments\//

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

          # find post identifier
          u = (attrs.do{|a|a.match(reRDFid)} ||
               inner.match(reLink) || inner.match(reLinkCD) || inner.match(reLinkAlt) || inner.match(reLinkRel) || inner.match(reGUID)).do{|s|s[1]}

          if u

            unless u.match /^http/ # bind paths to full URI
              u = (URI.join @base, u).to_s
            end

            resource = u.R

            # typetag
            if u.match commentRe
              yield u, R::Type, R[R::Post]
              yield u, R::To, R[resource.uri.match(commentRe).pre_match]
            else
              yield u, R::Type, R[R::SIOC+'BlogPost']
              yield u, R::To, R[resource.schemePart + resource.hostPart]
            end

            # media attachments
            inner.scan(reAttach){|e|
              e[1].match(reSrc).do{|url|
                rel = e[1].match reRel
                yield(u, R::Atom+rel[1], url[2].R) if rel}}

            # elements
            inner.scan(reElement){|e|

              # expand property-name
              p = (x[e[0] && e[0].chop]||R::RSS) + e[1]

              # custom element-type handle
              if [Atom+'id',RSS+'link',RSS+'guid',Atom+'link'].member? p 
                # bound as subject URI, drop redundant identifier-triple

              elsif [Atom+'author', RSS+'author', RSS+'creator', Purl+'dc/elements/1.1/creator'].member? p
                # author URI and name
                uri = e[3].match /<uri>([^<]+)</
                name = e[3].match /<name>([^<]+)</
                yield u, Creator, e[3].extend(SniffContent).sniff.do{|o|o.match(HTTP_URI) ? o.R : o } unless name||uri
                yield u, Creator, uri[1].R if uri
                if name
                  name = name[1]
                  yield u, Creator, (CGI.escapeHTML name) unless uri && uri[1].index(name.sub('/u/','/user/'))
                end


              else # generic element
                yield u,p,e[3].extend(SniffContent).sniff.do{|o|o.match(HTTP_URI) ? o.R : o }
              end
            }
          else
            puts "can't find identifier in #{@base}: #{inner}"
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
    opts = {:format => :feed}
    opts[:base_uri] = @r.R.join uri if @r
    RDF::Reader.open(pathPOSIX, opts){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s, o.class == R ? o : o.value}}
  end

  SlugStopper = /\b(at|blog|com(ments)?|html|info|medium|org|photo|p|post|r|rss|source|status|tag|twitter|utm|wordpress|www|1999|2005)\b/

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

  GET['feed'] = -> e {
    set = Set['page'][R('//'+e.host+Time.now.strftime('/%Y')).setEnv(e.env)]
    e.env[:Response].update({'Content-Type' => 'application/atom+xml', 'ETag' => set.sort.h})
    e.condResponse -> {
      graph = {}
      set.map{|r|r.loadGraph graph}
      Render['application/atom+xml'][graph,e]}}

end
