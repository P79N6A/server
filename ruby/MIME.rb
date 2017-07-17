# coding: utf-8
=begin triplrs

 We map from a file-ref to a triple-emitter function keyed on a MIME type which is derived from a filename suffix or prefix (unless
 neither exists in which case FILE(1) runs). A tripler uses #yield to relay intermediate results (triples) before the call returns,
 yielding 3 values, the first two being URI strings, the third a RDF::Literal-compatible value, RDF::URI or R (our resource-class).
 It's like a file read() call but for reading triples instead of bytes. triplrs allow quick one-line RDFizations of obscure formats
 without the boilerplate of a RDF::Reader instance, the latter now preferred for its greater interoperability with 3rd-party tools.
 We have a JSON format for a subset of RDF and use this for caching transcodes in a format readable by RDF parsers. As non-RDF
 formats usually can't express the full RDF model (even our JSON format omits blank-nodes), and editing is also nondestructive,
 we never "write back" to a non-RDF file (versions + edits can be Turtle) thus no RDF::Writer instances are defined here.
=end
class R

  MIMEprefix = {
    'capfile' => 'text/plain',
    'dockerfile' => 'text/plain',
    'gemfile' => 'application/ruby',
    'install' => 'text/plain',
    'license' => 'text/plain',
    'msg' => 'message/rfc822',
    'r' => 'text/plain',
    'rakefile' => 'application/ruby',
    'readme' => 'text/markdown',
  }

  MIMEsuffix = {
    'asc' => 'text/plain',
    'chk' => 'text/plain',
    'dat' => 'application/octet-stream',
    'e' => 'application/json',
    'eot' => 'application/font',
    'haml' => 'text/plain',
    'hs' => 'application/haskell',
    'ini' => 'text/plain',
    'ino' => 'application/ino',
    'md' => 'text/markdown',
    'msg' => 'message/rfc822',
    'list' => 'text/plain',
    'log' => 'text/chatlog',
    'ru' => 'text/plain',
    'rb' => 'application/ruby',
    'tmp' => 'application/octet-stream',
    'ttl' => 'text/turtle',
    'u' => 'text/uri-list',
    'woff' => 'application/font',
    'yaml' => 'text/plain',
  }

  Triplr = {
    'application/atom+xml' => [:triplrFeed],
    'application/font'      => [:triplrFile],
    'application/haskell'   => [:triplrSourceCode],
    'application/javascript' => [:triplrSourceCode],
    'application/ino'      => [:triplrSourceCode],
    'application/json'      => [:triplrSourceCode],
    'application/octet-stream' => [:triplrFile],
    'application/org'      => [:triplrOrg],
    'application/pdf'      => [:triplrFile],
    'application/pkcs7-signature' => [:triplrFile],
    'application/ruby'     => [:triplrSourceCode],
    'application/x-sh'     => [:triplrSourceCode],
    'application/xml'     => [:triplrSourceCode],
    'application/x-executable' => [:triplrFile],
    'application/x-gzip'   => [:triplrArchive],
    'audio/mpeg'           => [:triplrAudio],
    'audio/x-wav'          => [:triplrAudio],
    'audio/3gpp'           => [:triplrAudio],
    'image/bmp'            => [:triplrImage],
    'image/gif'            => [:triplrImage],
    'image/png'            => [:triplrImage],
    'image/svg+xml'        => [:triplrImage],
    'image/jpeg'           => [:triplrImage],
    'inode/directory'      => [:triplrContainer],
    'message/rfc822'       => [:triplrMail],
    'text/cache-manifest'  => [:triplrHref],
    'text/chatlog'         => [:triplrChatLog],
    'text/css'             => [:triplrSourceCode],
    'text/csv'             => [:triplrCSV,/,/],
    'text/html'            => [:triplrHTML],
    'text/man'             => [:triplrMan],
    'text/x-ruby'          => [:triplrSourceCode],
    'text/x-script.ruby'   => [:triplrSourceCode],
    'text/markdown'        => [:triplrMarkdown],
    'text/nfo'             => [:triplrHref,'cp437'],
    'text/plain'           => [:triplrHref],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values' => [:triplrCSV,/;/],
    'text/tab-separated-values' => [:triplrCSV,/\t/],
    'text/uri-list'        => [:triplrUriList],
    'text/x-tex'           => [:triplrTeX],
  }

  def mime
    @mime ||=
      (name = path || ''
       prefix = (File.basename name).split('.')[0].downcase
       suffix = ((File.extname name)[1..-1]||'').downcase
       if node.directory? # container
         'inode/directory'
       elsif MIMEprefix[prefix] # prefix mapping
         MIMEprefix[prefix]
       elsif MIMEsuffix[suffix] # suffix mapping
         MIMEsuffix[suffix]
       elsif Rack::Mime::MIME_TYPES['.'+suffix] # suffix mapping (Rack fallback)
         Rack::Mime::MIME_TYPES['.'+suffix]
       else # FILE(1)
         puts "WARNING unknown MIME of #{pathPOSIX}, sniffing (SLOW)"
         `file --mime-type -b #{Shellwords.escape pathPOSIX.to_s}`.chomp
       end)
  end

  def triplrArchive &f; yield uri, Type, R[Stat+'CompressedFile']; triplrFile false,&f end
  def triplrAudio &f;   yield uri, Type, R[Sound]; triplrFile false,&f end
  def triplrHTML &f;    yield uri, Type, R[Stat+'HTMLFile']; triplrFile false,&f end
  def triplrImage &f;   yield uri, Type, R[Image]; triplrFile false,&f end
  def triplrSourceCode &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -f html #{sh}`; triplrFile false,&f end
  def triplrMarkdown;   yield stripDoc.uri, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile) end
  def triplrRTF;        yield stripDoc.uri, Content, `which catdoc && catdoc #{sh}`.hrefs end
  def triplrTeX;        yield stripDoc.uri, Content, `cat #{sh} | tth -r` end

  def triplrContainer
    s = path # subject URI
    return unless s
    s += '/' unless s[-1] == '/' # give dirs a trailing-slash
    s = '/'+s unless s[0] == '/' # and a leading slash
    mt = mtime
    yield s, Type, R[Container]
    yield s, Mtime, mt.to_i
    yield s, Date, mt.iso8601
    # listing of children, using RDF Metadata
    dirs,files = children.partition{|e|e.node.directory?} # terminal nodes
    dirs.map{|d|yield d.uri, Type, R[Container]} # container nodes
    (R.load files).map{|s,r| # load children
      types = r.types
      # find nodes to summarize. just discard IMs for now, could select nodes that have a Title property or are files
      unless types.member?(SIOC+'InstantMessage') || types.member?(SIOC+'Tweet')
        r.map{|p,o| # visit resources
          o.justArray.map{|o|
            yield s, p, o
          } unless [Content,'uri',DC+'hasFormat',DC+'link'].member? p}
      end}
  end

  def triplrFile basicFile=true
    s = path || ''
    s = '/'+s unless s[0] == '/'
    yield s, Type, R[Stat+'File'] if basicFile
    mtime.do{|mt|
      yield s, Mtime, mt.to_i
      yield s, Date, mt.iso8601}
    size.do{|sz|
      yield s, Size, sz}
  end

  # scan for HTTP URIs in plain-text. example:
  # as you can see in the demo (https://suchlike) and find full source at https://stuffshere.com.
  # these decisions were made:
  # opening ( required for ) match, as referencing URLs inside () seems more common than URLs containing unmatched ()s [citation needed]
  # , and . only match mid-URI to allow usage of URIs as words in sentences ending in a period.
  # <> wrapping is supported
  Href = /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/
  def triplrHref enc=nil, &f
    id = stripDoc.uri
    yield id, Type, R[SIOC+'TextFile']
    yield id, Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: readFile.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs})
    triplrFile false,&f
  end

  def triplrCSV d
    lines = CSV.read pathPOSIX
    lines[0].do{|fields| # header-row
      yield uri, Type, R[CSVns+'Table']
      yield uri, CSVns+'rowCount', lines.size
      lines[1..-1].each_with_index{|row,line|
        row.each_with_index{|field,i|
          id = uri + '#row:' + line.to_s
          yield id, fields[i], field
          yield id, Type, R[CSVns+'Row']}}}
  end

  def uris; (open pathPOSIX).readlines.map &:chomp end
  def triplrUriList; uris.map{|u|yield u,Type,R[Resource]} end

  def isRDF; %w{n3 rdf owl ttl}.member? ext end
  def toRDF; isRDF ? self : toJSON end

  def toJSON # RDF-translation of resource (in JSON as RDF due to reader instance)
    return self if ext == 'e'
    hash = uri.sha1
    doc = R['/cache/'+hash[0..2]+'/'+hash[3..-1]+'.e'].setEnv @r
    unless doc.e && doc.m > m
      tree = {}
      triplr = Triplr[mime]
      unless triplr
        puts "WARNING missing #{mime} triplr for #{uri}"
        triplr = :triplrFile
      end
      send(*triplr){|s,p,o|
        tree[s] ||= {'uri' => s}
        tree[s][p] ||= []
        tree[s][p].push o}
      doc.writeFile tree.to_json
    end
    doc
  end

  module Format

    class Format < RDF::Format
      content_type     'application/json+rdf', :extension => :e
      content_encoding 'utf-8'
      reader { R::Format::Reader }
    end

    class Reader < RDF::Reader
      format Format

      def initialize(input = $stdin, options = {}, &block)
        @graph = JSON.parse (input.respond_to?(:read) ? input : StringIO.new(input.to_s)).read
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
        @graph.map{|s,r|
          r.map{|p,o|
            o.justArray.map{|o|
              fn.call RDF::Statement.new(@base.join(s), RDF::URI(p),
                        o.class==Hash ? @base.join(o['uri']) : (l = RDF::Literal o
                                                              l.datatype=RDF.XMLLiteral if p == Content
                                                              l))}}}
      end
      def each_triple &block; each_statement{|s| block.call *s.to_triple} end
    end
  end

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

  def triplrChatLog &f
    linenum = -1
    day = dirname.match(/\/(\d{4}\/\d{2}\/\d{2})/).do{|d|d[1].gsub('/','-')} || Time.now.iso8601[0..9]
    chan = R[stripDoc.basename]
    readFile.lines.map{|l|
      #       19:02 <mngrif(:#logbook)> good deal
      l.scan(/(\d\d):(\d\d) <[\s+@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = stripDoc + '#l' + (linenum += 1).to_s
        yield s, Type, R[SIOC+'InstantMessage']
        yield s, Creator, R['#'+m[2]]
        yield s, To, chan
        yield s, Content, m[3].hrefs{|p, o| yield s, p, o}
        yield s, Date, day+'T'+m[0]+':'+m[1]+':00'
        yield s, DC + 'source', self
      }
    }
  rescue Exception => e
    puts [uri, e.class, e.message, e.backtrace[0..2].join("\n")].join " "
  end

  def triplrMail &b

    # load
    m = Mail.read node
    return unless m

    # identifier and storage
    id = m.message_id || m.resent_message_id || rand.to_s.sha1 # find Message-ID
    e = MessagePath[id] # derive path from Message-ID field
    canonicalLocation = e.R + '.msg' # storage location
    canonicalLocation.dir.mkdir # link to canonical location if found elsewhere
    FileUtils.ln pathPOSIX, canonicalLocation.pathPOSIX unless canonicalLocation.e
    yield e, DC+'identifier', id                # preserve Message-ID
    yield e, DC+'source', self                  # point to originating file
    yield e, Type, R[SIOC+'MailMessage']        # RDF typetag
    yield e, SIOC+'has_discussion', R[e+'?rev'] # discussion link
    indexAddrs = []

    # From
    m.from.do{|f|f.justArray.map{|f|         # source
                address = f.to_utf8.downcase # source address
                yield e, Creator, AddrPath[address].R # source triple
                indexAddrs.push address      # mark for address-indexing
              }}
    m[:from].do{|fr|fr.addrs.map{|a|yield e, Creator, a.display_name||a.name}} # source name

    # To
    %w{to cc bcc resent_to}.map{|p|      # header fields
      m.send(p).justArray.map{|to|       # recipient
        address = to.to_utf8.downcase    # recipient address
        yield e, To, AddrPath[address].R # recipient triple
        indexAddrs.push address }}       # mark for address-indexing
    m['X-BeenThere'].justArray.map{|to|  # anti-loop address
      yield e, To, AddrPath[to.to_s].R }
    m['List-Id'].do{|name|
      yield e, To, name.decoded.sub(/<[^>]+>/,'').gsub(/[<>&]/,'')} # list name

    # Subject
    subject = nil
    m.subject.do{|s|
      subject = s.to_utf8.gsub(/\[[^\]]+\]/){|l|
        yield e, Label, l[1..-2]; nil} # emit bracketed portions as RDF labels
      yield e, Title, subject}

    # Date
    if m.date
      date = m.date.to_time.utc
      dstr = date.iso8601
      yield e, Date, dstr
      yield e, Mtime, date.to_i
      # link message to date-address index
      dpath = '/' + dstr[0..6].gsub('-','/') + '/addr/' # date part
      indexAddrs.map{|addr| # addresses
        apath = dpath + addr.sub('@','.') + '/' # address part
        if subject
          mpath = apath + (dstr[8..-1] + subject).gsub(/[^a-zA-Z0-9_]+/,'.') # subject part
          mpath = mpath + (mpath[-1] == '.' ? '' : '.')  + 'msg' # filename extension
          mloc = mpath.R # file resource
          mloc.dir.mkdir # containing directory
          FileUtils.ln pathPOSIX, mloc.pathPOSIX unless mloc.e # write
        end}
    end

    # references
    %w{in_reply_to references}.map{|ref|             # reference predicates
     m.send(ref).do{|rs| rs.justArray.map{|r|        # indirect-references
      yield e, SIOC+'reply_of', R[MessagePath[r]]}}} # reference URI
    m.in_reply_to.do{|r|                             # direct-reference predicate
      yield e, SIOC+'has_parent', R[MessagePath[r]]} # reference URI

    # body
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
        elsif l.match(/^((At|On)\b.*wrote:|_+|[a-zA-Z\-]+ mailing list)$/) # attribution
          l.gsub('@','.').hrefs # obfuscate addresses
        else # fresh line
          [l.hrefs{|p,o| # hypertextify plaintext
             yield e, p, o}] # links in RDF
        end}.compact.intersperse("\n")
      yield e, Content, body}

    # attachments
    attache = -> {(e.R+'.attache').mkdir} # container for attachments
    htmlCount = 0
    htmlFiles.map{|p| # HTML
      html = attache[].child "#{htmlCount}.html" # file-path
      yield e, DC+'hasFormat', html              # point to HTML format
      html.writeFile p.decoded  if !html.e       # store to node
      htmlCount += 1 } # increment file-count
    parts.select{|p|p.mime_type=='message/rfc822'}.map{|m| # recursive mail-containers (digests + forwards)
      f = attache[].child 'msg.' + rand.to_s.sha1 # file path
      f.writeFile m.body.decoded if !f.e # store to node
      f.triplrMail &b} # recur
    m.attachments.select{|p|Mail::Encodings.defined?(p.body.encoding)}.map{|p|
      name = p.filename.do{|f|f.to_utf8.do{|f|!f.empty? && f}} || # supplied file-name
             (rand.to_s.sha1 + (Rack::Mime::MIME_TYPES.invert[p.mime_type] || '.bin').to_s) # generate name
      file = attache[].child name              # file path
      file.writeFile p.body.decoded if !file.e # store to node
      yield e, SIOC+'attachment', file         # point to attachment
      if p.main_type=='image'                  # image attachment?
        yield e, Image, file                   # image link (RDF)
        yield e, Content,                      # image link (HTML)
          H({_: :a, href: file.uri, c: [{_: :img, src: file.uri}, p.filename]})
      end }
  end

  def fetchFeeds; uris.map(&:R).map &:fetchFeed end
  def fetchFeed
    head = {} # request header
    cache = R['/cache/'+uri.sha1]  # cache URI
    etag = cache.child 'etag'      # cached etag URI
    priorEtag = nil                # cached etag value
    mtime = cache.child 'mtime'    # cached mtime URI
    priorMtime = nil               # cached mtime value
    body = cache.child 'body.atom' # cached body URI
    if etag.e
      priorEtag = etag.readFile
      head["If-None-Match"] = priorEtag unless priorEtag.empty?
    elsif mtime.e
      priorMtime = mtime.readFile.to_time
      head["If-Modified-Since"] = priorMtime.httpdate
    end
    begin # conditional GET
      open(uri, head) do |response|
        curEtag = response.meta['etag']
        curMtime = response.last_modified || Time.now rescue Time.now
        etag.writeFile curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag # new ETag header
        mtime.writeFile curMtime.iso8601 if curMtime != priorMtime # new Last-Modified header
        resp = response.read
        unless body.e && body.readFile == resp
          body.writeFile resp
          ('file:'+body.pathPOSIX).R.indexFeed :format => :feed, :base_uri => uri
        end
      end
    rescue OpenURI::HTTPError => error
      msg = error.message
      puts [uri,msg].join("\t") unless msg.match(/304/) # print return-type unless OK or cache-hit (304)
    end
    self
  rescue Exception => e
    puts [uri, e.class, e.message, e.backtrace[0..2].join("\n")].join " "
  end
  alias_method :getFeed, :fetchFeed

  def triplrTwitter
    base = 'https://twitter.com'
    nokogiri.css('div.tweet > div.content').map{|t|
      s = base + t.css('.js-permalink').attr('href') # subject URI
      author = R[base+'/'+t.css('.username b')[0].inner_text]
      yield s, Type, R[SIOC+'Tweet']
      yield s, Date, Time.at(t.css('[data-time]')[0].attr('data-time').to_i).iso8601
      yield s, Creator, author
      content = t.css('.tweet-text')[0]
      content.css('a').map{|a| # resolve paths with remote base
        a.set_attribute('href',base + (a.attr 'href')) if (a.attr 'href').match /^\//
        yield s, DC+'link', R[a.attr 'href']
      }
      yield s, Content, StripHTML[content.inner_html].gsub(/<\/?span[^>]*>/,'').gsub(/\n/,'').gsub(/\s+/,' ')}
  end

  def indexTweets; graph = {}
    triplrTwitter{|s,p,o|
      graph[s] ||= {'uri' => s}; graph[s][p]||=[]; graph[s][p].push o}
    graph.map{|u,r|
      r[Date].do{|t|# timestamp required to place on timeline
          slug = (u.sub(/https?/,'.').gsub(/\W/,'.')).gsub /\.+/,'.'
          time = t[0].to_s.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
          doc = "//localhost/#{time}#{slug}.e".R # doc URI
          docP = doc.justPath
          unless doc.e || docP.e
            docP.dir.mkdir
            doc.writeFile({u => r}.to_json) # hosted doc
            FileUtils.ln doc.pathPOSIX, docP.pathPOSIX # local doc
            puts docP
          end}}
  end

  def indexFeed options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t| # find timestamp
        time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..127].sub(/\.$/,'')
        doc =  R["//localhost/#{time}#{slug}.ttl"]
        docP = doc.justPath
        unless doc.e || docP.e
          [doc,docP].map{|d|d.dir.mkdir} # container
          RDF::Writer.open(doc.pathPOSIX){|f|f << graph} # hosted link (GC after sync)
          FileUtils.ln doc.pathPOSIX, docP.pathPOSIX # local link
          puts docP
        end
        true}}
    self
  rescue Exception => e
    puts uri, e.class, e.message , e.backtrace[0..2]
  end

  def feeds; (nokogiri.css 'link[rel=alternate]').map{|u|join u.attr :href} end

  module Feed # feed parser defined as RDF parser

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
      def each_statement &fn # triples flow left ← right across stream-transformer stack
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
                 RSS+'title' => Title,
                 RSS+'description' => Content,
                 RSS+'encoded' => Content,
                 RSS+'modules/slash/comments' => SIOC+'num_replies',
                 RSS+'modules/content/encoded' => Content,
                 RSS+'category' => Label,
                 RSS+'source' => DC+'source',
                 Podcast+'keywords' => Label,
                 Podcast+'author' => Creator,
                 Atom+'displaycategories' => Label,
                 Atom+'content' => Content,
                 Atom+'summary' => Content,
                 Atom+'enclosure' => SIOC+'attachment',
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
      def rawTriples # allow broken XML, missing quotes around values, and arbitrary feature-use mashup
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
          # identifier search. try RDF identifier then <link> as they're more likely to be a href than <id>
          u = (attrs.do{|a|a.match(reRDF)} || inner.match(reLink) || inner.match(reLinkCData) || inner.match(reLinkHref) || inner.match(reLinkRel) || inner.match(reId)).do{|s|s[1]}
          if u
            unless u.match /^http/ # resolve relative-reference
              u = (URI.join @base, u).to_s
            end
            resource = u.R
            if u.match commentRe
              yield u, R::Type, R[R::Post]
              yield u, R::To, R[resource.uri.match(commentRe).pre_match]
            else
              yield u, R::Type, R[R::SIOC+'BlogPost']
              blogs = [resource.join('/')]
              blogs.push @base.R.join('/') if @base.R.host != resource.host
              blogs.map{|blog| yield u, R::To, blog}
            end
            inner.scan(reAttach){|e| # media links
              e[1].match(reSrc).do{|url|
                rel = e[1].match reRel
                yield(u, R::Atom+rel[1], url[2].R) if rel}}
            inner.scan(reElement){|e| # elements
              p = (x[e[0] && e[0].chop]||R::RSS) + e[1]                  # expand property-name
              if [Atom+'id',RSS+'link',RSS+'guid',Atom+'link'].member? p # custom element-type handlers
                # used in subject URI search
              elsif [Atom+'author', RSS+'author', RSS+'creator', Purl+'dc/elements/1.1/creator'].member? p # author
                uri = e[3].match /<uri>([^<]+)</
                name = e[3].match /<name>([^<]+)</
                yield u, Creator, e[3].do{|o|o.match(/\A(\/|http)[\S]+\Z/) ? o.R : o } unless name||uri
                yield u, Creator, uri[1].R if uri
                if name
                  name = name[1]
                  yield u, Creator, (CGI.escapeHTML name) unless uri && uri[1].index(name.sub('/u/','/user/'))
                end
              else # generic element
                yield u,p,e[3].do{|o|
                  case o
                  when /^\s*<\!\[CDATA/m
                    o.sub /^\s*<\!\[CDATA\[(.*?)\]\]>\s*$/m,'\1'
                  when /</m
                    o
                  else
                    CGI.unescapeHTML o
                  end
                }.do{|o|o.match(/\A(\/|http)[\S]+\Z/) ? o.R : o }
              end
            }
          else
            puts "no identifier found in #{@base}: #{inner}"
          end}
      end
    end
  end
end

module Redcarpet
  module Render
    class Pygment < HTML
      def block_code(code, lang)
        if lang
          IO.popen("pygmentize -l #{lang.downcase.sh} -f html",'r+'){|p|
            p.puts code
            p.close_write
            p.read
          }
        else
          code
        end
      end
    end
  end
end
