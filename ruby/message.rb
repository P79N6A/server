# coding: utf-8
class R

  Abstract[SIOC+'InstantMessage'] = -> graph, msgs, re {
    msgs.map{|uri,msg|

      # init channel bin
      bin = msg[DC+'source'].justArray[0].uri
      graph[bin] ||= {'uri' => bin+'.html',
                      Type => R[SIOC+'Discussion'],
                      Title => msg[To].justArray[0].R.fragment,
                      Size => 0}

      graph[bin][Size] += 1 # increment bin size

      if re.env[:grep] # keep content for grep filtering
        msg[Content].do{|c|
          graph[bin][Content] ||= []
          graph[bin][Content].concat c}
      end

      # add images and links to bin
      msg[Image].do{|images|
        graph[bin][Image] ||= []
        graph[bin][Image].concat images}
      msg[DC+'link'].do{|links|
        graph[bin][DC+'link'] ||= []
        graph[bin][DC+'link'].concat links}

      # drop raw message
      graph.delete uri
    }
  }

  Abstract[SIOC+'MailMessage'] = -> graph, g, e {
    threads = {}
    weight = {}

    # pass 1. statistics & prune
    g.map{|u,p|

      # trim fat from summarized graph
      graph.delete u
      p[Creator].justArray.select{|t|t.respond_to? :uri}.map{|r|graph.delete r.uri}
      recipients = p[To].justArray.select{|r|r.respond_to? :uri}.map &:uri
      recipients.map{|r|graph.delete r}

      # group by subject
      p[Title].do{|t|
        title = t[0].sub ReExpr, '' # strip reply-prefix
        if threads[title] # add to group
          threads[title][Size] += 1
          threads[title][Creator].concat p[Creator]
        else # initialize group
          p[Size] = 1         #  member-count
          threads[title] = p  #  title
        end}

      recipients.map{|a| # recipient weights
        weight[a] ||= 0
        weight[a] += 1}}

    # pass 2. complete thread/discussion resources, add to graph
    threads.map{|title,post|
      # heaviest recipient wins
      post[To].justArray.select{|t|t.respond_to? :uri}.sort_by{|a|weight[a.uri]}[-1].do{|to|
        labels = []
        # resource pointing to post(s)
        thread = {'uri' => '/thread/' + URI.escape(post[DC+'identifier'][0]),
                  Type => R[Post],
                  To => to,
                  Title => title.gsub(/\[[^\]]+\]/){|l|labels.push l[1..-2];nil},
                  Date => post[Date],
                  Creator => post[Creator],
                  Image => post[Image],
                  Content => e.env[:grep] ? post[Content] : []}
        # extract labels from subject text to RDF
        thread.update({Label => labels}) unless labels.empty?
        # if >1 post add discussion typetag and size-attribute
        thread.update({Size => post[Size], Type => R[SIOC+'Thread']}) if post[Size] > 1

        # link resource to graph
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
    ['', 'address', tld, domain[0], domain, *dname[2..-1], id.sha1[0..1], msg].join('/')}

  AddrPath = ->address{ # email-address -> path
    address = address.downcase
    person, domainname = address.split '@'
    dname = (domainname||'').split('.').reverse
    tld = dname[0]
    domain = dname[1] || 'localdomain'
    ['', 'address', tld, domain[0], domain, *dname[2..-1], person,''].join('/') + person + '#' + person}


  def triplrIRC &f
    doc = uri.gsub('#','%23').R
    linenum = -1
    day = dirname.match(/\/(\d{4}\/\d{2}\/\d{2})/).do{|d|d[1].gsub('/','-')} || Time.now.iso8601[0..9]
    chan = R['#'+uri.split('#')[-1].sub(/\.log$/,'')]
    r.lines.map{|l|
      l.scan(/(\d\d):(\d\d) <[\s@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = uri + '#' + (linenum += 1).to_s
        yield s, Type, R[SIOC+'InstantMessage']
        yield s, Creator, R['#'+m[2]]
        yield s, To, chan
        yield s, Content, m[3].hrefs{|p, o| yield s, p, o}
        yield s, Date, day+'T'+m[0]+':'+m[1]+':00'
        yield s, DC + 'source', doc
      }
    }
  rescue
    puts 'error scanning IRC log ' + uri
  end

  def triplrMailIndexer &f; indexStream :triplrMail, &f end

  def triplrMail &b
    m = Mail.read node # call parser
    return unless m

    # mint identifier for message
    id = m.message_id || m.resent_message_id
    unless id
      puts "missing Message-ID in #{uri}"
      id = rand.to_s.sha1
    end

    # emit graph-ized data as RDF triples
    e = MessagePath[id]
    yield e, DC+'identifier', id
    yield e, DC+'source', self # reference to origin-file
    yield e, Type, R[SIOC+'MailMessage']

    list = m['List-Post'].do{|l|l.decoded.sub(/.*?<?mailto:/,'').sub(/>$/,'').downcase} # list address
    list && list.match(/@/) && m['List-Id'].do{|name|
      group = AddrPath[list]                            # list URI
      yield group, Type, R[SIOC+'Usergroup']            # list type
      yield group, Label, name.decoded.gsub(/[<>&]/,'') # list name
      yield group, SIOC+'has_container', group.R.dir    # list container
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

    m[:from].do{|fr|
      fr.addrs[0].do{|a|
        author = AddrPath[a.address]
        yield author, Label, a.display_name||a.name
        yield author, SIOC+'has_container', author.R.dir
      }}

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

    parts.select{|p|p.mime_type=='message/rfc822'}.map{|m| # recursive mail-containers (digests + forwards)
      f = attache[].child 'msg.' + rand.to_s.sha1
      f.w m.body.decoded if !f.e
      f.triplrMail &b
    }

    m.attachments.                                    # attached
      select{|p|Mail::Encodings.defined?(p.body.encoding)}.map{|p|
      name = p.filename.do{|f|f.to_utf8.do{|f|!f.empty? && f}} || (rand.to_s.sha1 + '.' + (MIME.invert[p.mime_type] || 'bin').to_s)
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

  def fetchFeeds
    uris.map &:fetchFeed
    self
  end
  def fetchFeed
    head = {} # request header
    cache = R['/cache/'+uri.sha1]  # cache URI
    etag = cache.child 'etag'      # cached etag URI
    priorEtag = nil                # cached etag value
    mtime = cache.child 'mtime'    # cached mtime URI
    priorMtime = nil               # cached mtime value
    body = cache.child 'body.atom' # cached body URI

    if etag.e
      priorEtag = etag.r
      head["If-None-Match"] = priorEtag unless priorEtag.empty?
    elsif mtime.e
      priorMtime = mtime.r.to_time
      head["If-Modified-Since"] = priorMtime.httpdate
    end

    begin # conditional GET
      open(uri, head) do |response|
        curEtag = response.meta['etag']
        curMtime = response.last_modified || Time.now rescue Time.now
        etag.w curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag
        mtime.w curMtime.iso8601 if curMtime != priorMtime
        resp = response.read
        unless body.e && body.r == resp
          body.w resp # store to local file
          ('file://'+body.pathPOSIX).R.indexResource :format => :feed, :base_uri => uri
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
  alias_method :getFeed, :fetchFeed

  def listFeeds; (nokogiri.css 'link[rel=alternate]').map{|u|R (URI uri).merge(u.attr :href)} end
  alias_method  :feeds, :listFeeds

  module Feed # feed parser defined as RDF library method
    
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

      def each_triple &block; each_statement{|s| block.call *s.to_triple} end      

      def each_statement &fn # triples flow from right to left across stacked stream-transformers
        resolveURIs(:normalizeDates, :normalizePredicates,:rawTriples){|s,p,o|
          fn.call RDF::Statement.new(s.R, p.R,
                                     (o.class == R || o.class == RDF::URI) ? o : (l = RDF::Literal (if p == Content
                                                                             R::StripHTML[o]
                                                                           else
                                                                             o.gsub(/<[^>]*>/,' ')
                                                                           end)
                                                         l.datatype=RDF.XMLLiteral if p == Content
                                                         l), :graph_name => s.R)}
      end

      def resolveURIs *f
        send(*f){|s,p,o|
          if Content==p && o.class==String
            content = Nokogiri::HTML.fragment o
            content.css('a').map{|a|
              a.set_attribute 'href', (URI.join s, (a.attr 'href')) if a.has_attribute? 'href' rescue nil}
            content.css('span > a').map{|a|
              if a.inner_text=='[link]'
                yield s, DC+'link', a.attr('href').R 
                a.remove
              end}
            yield s, p, content.to_xhtml
          else
            yield s, p, o
          end
        }
      end

      def normalizePredicates *f
        send(*f){|s,p,o|
          yield s,
                {Purl+'dc/elements/1.1/subject' => SIOC+'subject',
                 RSS+'description' => Content,
                 RSS+'encoded' => Content,
                 RSS+'modules/content/encoded' => Content,
                 RSS+'category' => Label,
                 RSS+'modules/slash/comments' => SIOC+'num_replies',
                 Atom+'content' => Content,
                 Atom+'summary' => Content,
                 RSS+'title' => Title,
                 Atom+'title' => Title,
                }[p]||p, o }
      end

      def normalizeDates *f
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

      def rawTriples # regex allowing nonconformant XML, missing ' around values, arbitrary rss1/rss2/Atom feature-use mashup

        # elements
        reHead = /<(rdf|rss|feed)([^>]+)/i
        reXMLns = /xmlns:?([a-z0-9]+)?=["']?([^'">\s]+)/
        reItem = %r{<(?<ns>rss:|atom:)?(?<tag>item|entry)(?<attrs>[\s][^>]*)?>(?<inner>.*?)</\k<ns>?\k<tag>>}mi
        reElement = %r{<([a-z0-9]+:)?([a-z]+)([\s][^>]*)?>(.*?)</\1?\2>}mi

        # identifiers
        reRDF = /about=["']?([^'">\s]+)/              # RDF @about
        reLink = /<link>([^<]+)/                      # <link> element
        reLinkCData = /<link><\!\[CDATA\[([^\]]+)/    # <link> CDATA block
        reLinkHref = /<link[^>]+rel=["']?alternate["']?[^>]+href=["']?([^'">\s]+)/ # <link> @href @rel=alternate
        reLinkRel = /<link[^>]+href=["']?([^'">\s]+)/ # <link> @href
        reId = /<(?:gu)?id[^>]*>([^<]+)/              # <id> element

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

          # find post id. try RDF identifier then <link> as they're more likely to be a resolving hyperlink than gunk (tag: URI etc) in <id> element
          u = (attrs.do{|a|a.match(reRDF)} || inner.match(reLink) || inner.match(reLinkCData) || inner.match(reLinkHref) || inner.match(reLinkRel) || inner.match(reId)).do{|s|s[1]}

          if u

            unless u.match /^http/ # resolve relative reference
              u = (URI.join @base, u).to_s
            end

            resource = u.R

            # typetag
            if u.match commentRe
              yield u, R::Type, R[R::Post]
              yield u, R::To, R[resource.uri.match(commentRe).pre_match]
            else
              yield u, R::Type, R[R::SIOC+'BlogPost']
              blogs = [resource.join('/')]
              # include provenance of reblogs, as on http://cambridgehappenings.org
              blogs.push @base.R.join('/') if @base.R.host != resource.host
              blogs.map{|blog|
                yield u, R::To, blog}
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
                yield u, Creator, e[3].extend(SniffContent).sniff.do{|o|o.match(/\A(\/|http)[\S]+\Z/) ? o.R : o } unless name||uri
                yield u, Creator, uri[1].R if uri
                if name
                  name = name[1]
                  yield u, Creator, (CGI.escapeHTML name) unless uri && uri[1].index(name.sub('/u/','/user/'))
                end


              else # generic element
                yield u,p,e[3].extend(SniffContent).sniff.do{|o|o.match(/\A(\/|http)[\S]+\Z/) ? o.R : o }
              end
            }
          else
            puts "can't find identifier in #{@base}: #{inner}"
          end
        }

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

end
