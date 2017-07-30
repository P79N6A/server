# coding: utf-8
=begin formats

 We define a JSON format and its RDF::Reader instance, used for internal caching and leveraging the optimized
 nature of the standard-library JSON parser and the Hash-class in-memory representation and utility functions,

 and enable non-RDF to RDF conversion of documents via triplr functions defined on non-RDF MIMEs. these yield
 (rather than return) trios of values: two URI strings describing the resource and an attribute, + a RDF::Literal
 or RDF::URI (or trivially-convertible value: basic string/numeric values and R, our RDF::URI derived "resource").
 
 the HTTP daemon swaps non-RDF file-references w/ cached RDF substitutes and uses the stock abstract RDF-loader.

=end
class R

  MIMEprefix = {
    'capfile' => 'text/plain',
    'config' => 'application/config',
    'dockerfile' => 'text/plain',
    'gemfile' => 'application/ruby',
    'install' => 'text/plain',
    'license' => 'text/plain',
    'makefile' => 'application/makefile',
    'msg' => 'message/rfc822',
    'r' => 'text/plain',
    'rakefile' => 'application/ruby',
    'readme' => 'text/markdown',
  }

  MIMEsuffix = {
    'asc' => 'text/plain',
    'chk' => 'text/plain',
    'conf' => 'application/config',
    'desktop' => 'application/config',
    'doc' => 'application/msword',
    'docx' => 'application/msword+xml',
    'dat' => 'application/octet-stream',
    'db' => 'application/octet-stream',
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
    'rst' => 'text/restructured',
    'sample' => 'application/config',
    'terminfo' => 'application/config',
    'tmp' => 'application/octet-stream',
    'ttl' => 'text/turtle',
    'u' => 'text/uri-list',
    'woff' => 'application/font',
    'yaml' => 'text/plain',
  }

  Triplr = {
    'application/config'   => [:triplrDataFile],
    'application/font'      => [:triplrFile],
    'application/haskell'   => [:triplrSourceCode],
    'application/javascript' => [:triplrSourceCode],
    'application/ino'      => [:triplrSourceCode],
    'application/json'      => [:triplrDataFile],
    'application/octet-stream' => [:triplrFile],
    'application/org'      => [:triplrOrg],
    'application/pdf'      => [:triplrFile],
    'application/makefile'      => [:triplrSourceCode],
    'application/msword'   => [:triplrWordDoc],
    'application/msword+xml' => [:triplrWordXML],
    'application/pkcs7-signature' => [:triplrFile],
    'application/rtf'      => [:triplrRTF],
    'application/ruby'     => [:triplrSourceCode],
    'application/sh'      => [:triplrSourceCode],
    'application/x-sh'     => [:triplrSourceCode],
    'application/xml'     => [:triplrDataFile],
    'application/x-executable' => [:triplrFile],
    'application/x-gzip'   => [:triplrArchive],
    'application/vnd.oasis.opendocument.text' => [:triplrOpenDocument],
    'audio/mpeg'           => [:triplrAudio],
    'audio/x-wav'          => [:triplrAudio],
    'audio/3gpp'           => [:triplrAudio],
    'image/bmp'            => [:triplrImage],
    'image/gif'            => [:triplrImage],
    'image/png'            => [:triplrImage],
    'image/svg+xml'        => [:triplrImage],
    'image/tiff'           => [:triplrImage],
    'image/jpeg'           => [:triplrImage],
    'inode/directory'      => [:triplrContainer],
    'message/rfc822'       => [:triplrMail],
    'text/cache-manifest'  => [:triplrText],
    'text/chatlog'         => [:triplrChatLog],
    'text/css'             => [:triplrSourceCode],
    'text/csv'             => [:triplrCSV,/,/],
    'text/html'            => [:triplrHTML],
    'text/man'             => [:triplrMan],
    'text/x-c'             => [:triplrSourceCode],
    'text/x-ruby'          => [:triplrSourceCode],
    'text/x-script.ruby'   => [:triplrSourceCode],
    'text/markdown'        => [:triplrMarkdown],
    'text/nfo'             => [:triplrText,'cp437'],
    'text/plain'           => [:triplrText],
    'text/restructured'    => [:triplrMarkdown],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values' => [:triplrCSV,/;/],
    'text/tab-separated-values' => [:triplrCSV,/\t/],
    'text/uri-list'        => [:triplrUriList],
    'text/x-tex'           => [:triplrTeX],
  }

  Icons = {
    'uri' => :id,
    Type => :type,
    Container => :dir,
    Content => :pencil,
    Date => :date,
    Label => :tag,
    Title => :title,
    Sound => :speaker,
    Image => :img,
    Size => :size,
    Mtime => :time,
    To => :userB,
    DC+'hasFormat' => :file,
    Schema+'location' => :location,
    Stat+'File' => :file,
    Stat+'Archive' => :archive,
    Stat+'HTMLFile' => :html,
    Stat+'WordDocument' => :word,
    Stat+'DataFile' => :tree,
    Stat+'TextFile' => :textfile,
    Stat+'container' => :dir,
    SIOC+'BlogPost' => :pencil,
    SIOC+'ChatLog' => :comments,
    SIOC+'Discussion' => :comments,
    SIOC+'InstantMessage' => :comment,
    SIOC+'MicroblogPost' => :newspaper,
    SIOC+'WikiArticle' => :pencil,
    SIOC+'Tweet' => :tweet,
    SIOC+'Usergroup' => :group,
    SIOC+'SourceCode' => :code,
    SIOC+'has_creator' => :user,
    SIOC+'has_discussion' => :comments,
    SIOC+'Thread' => :openenvelope,
    SIOC+'Post' => :newspaper,
    SIOC+'MailMessage' => :envelope,
    SIOC+'has_parent' => :reply,
    SIOC+'reply_to' => :reply,
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
  def isRDF; %w{atom n3 rdf owl ttl}.member? ext end

  def triplrArchive &f; yield uri, Type, R[Stat+'Archive']; triplrFile false,&f end
  def triplrAudio &f;   yield uri, Type, R[Sound]; triplrFile false,&f end
  def triplrHTML &f;    yield uri, Type, R[Stat+'HTMLFile']; triplrFile false,&f end
  def triplrImage &f;   yield uri, Type, R[Image]; triplrFile false,&f end
  def triplrDataFile &f; yield uri, Type, R[Stat+'DataFile']; triplrFile false,&f end
  def triplrSourceCode &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -f html #{sh}`; triplrFile false,&f end
  def triplrMarkdown;   yield stripDoc.uri, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile) end
  def triplrTeX;        yield stripDoc.uri, Content, `cat #{sh} | tth -r` end
  def triplrUriList; uris.map{|u|yield u,Type,R[W3+'2000/01/rdf-schema#Resource']} end
  def triplrRTF          &f; triplrWord :catdoc,        &f end
  def triplrWordDoc      &f; triplrWord :antiword,      &f end
  def triplrWordXML      &f; triplrWord :docx2txt, '-', &f end
  def triplrOpenDocument &f; triplrWord :odt2txt,       &f end

  def triplrContainer
    s = path # subject URI
    return unless s
    # so we don't get 4 id for 1 resource, normalize URI
    s += '/' unless s[-1] == '/' # trailing slash
    s = '/'+s unless s[0] == '/' # leading slash
    mt = mtime
    yield s, Type, R[Container]
    yield s, Mtime, mt.to_i
    yield s, Date, mt.iso8601
    # preview children using RDF and filesystem metadata
    dirs,files = children.partition{|e|e.node.directory?}
    dirs.map{|d|yield d.uri + d.uri[-1]=='/' ? '' : '/', Type, R[Container]} # container in container. don't inline recursively here, emit a pointer
    (R.load files.select &:e).map{|s,r| # leaf nodes. fetch RDF
      types = r.types
      unless types.member?(SIOC+'InstantMessage') || types.member?(SIOC+'Tweet') # node-types to drop. dropped classes emit summary-nodes, as seen in triplrChatLog
        r.map{|p,o| o.justArray.map{|o| # visit triples
            yield s, p, o # emit summary triples for directory-data graph
          } unless [Content,'uri',DC+'hasFormat'].member? p} # arc types to drop
      end}
  end

  def triplrFile basicFile=true
    s = path || ''
    s = '/'+s unless s[0] == '/'
    yield s, Stat+'container', dir
    yield s, Type, R[Stat+'File'] if basicFile
    mtime.do{|mt|
      yield s, Mtime, mt.to_i
      yield s, Date, mt.iso8601}
    size.do{|sz|
      yield s, Size, sz}
  end

  def triplrWord conv, out='', &f
    triplrFile false, &f
    yield uri, Type, R[Stat+'WordDocument']
    yield uri, Content, '<pre>' +
                        `#{conv} #{sh} #{out}` +
                        '</pre>'
  end

  def triplrText enc=nil, &f
    yield uri, Type, R[Stat+'TextFile']
    yield uri, Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: readFile.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs})
    triplrFile false,&f
  end

  def triplrCSV d
    ns    = W3 + 'ns/csv#'
    lines = CSV.read pathPOSIX
    lines[0].do{|fields| # header-row
      yield uri, Type, R[ns+'Table']
      yield uri, ns+'rowCount', lines.size
      lines[1..-1].each_with_index{|row,line|
        row.each_with_index{|field,i|
          id = uri + '#row:' + line.to_s
          yield id, fields[i], field
          yield id, Type, R[ns+'Row']}}}
  end

  def uris; (open pathPOSIX).readlines.map &:chomp end

  # substitute non-RDF file reference with a RDF transcode
  def toRDF; isRDF ? self : toJSON end
  def toJSON # non-RDF file to JSON+RDF-file
    return self if ext == 'e'
    hash = uri.sha1
    doc = R['/cache/'+hash[0..2]+'/'+hash[3..-1]+'.e'].setEnv @r # cache location
    unless doc.e && doc.m > m # update cache
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
  # Reader for minimalist JSON-RDF format used by cache
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

  AddrPath = -> address { # email-address -> path
    address = address.downcase
    person, domainname = address.split '@'
    dname = (domainname||'').split('.').reverse
    tld = dname[0]
    domain = dname[1] || 'localdomain'
    ['', 'address', tld, domain[0], domain, *dname[2..-1], person,''].join('/') + person + '#' + person}

  def triplrChatLog &f
    linenum = -1
    base = justPath.stripDoc
    dir = base.dir
    log = base.uri
    basename = base.basename
    channel = dir + '/' + basename
    network = dir + '/' + basename.split('%23')[0] + '*'
    day = dir.uri.match(/\/(\d{4}\/\d{2}\/\d{2})/).do{|d|d[1].gsub('/','-')}
    readFile.lines.map{|l|
      l.scan(/(\d\d):(\d\d) <[\s+@]*([^\(>]+)[^>]*> (.*)/){|m|
        s = base + '#l' + (linenum += 1).to_s
        yield s, Type, R[SIOC+'InstantMessage']
        yield s, Creator, R['#'+m[2]]
        yield s, To, channel
        yield s, Content, m[3].hrefs{|p, o|
          yield log, p, o
          yield s, p, o
        }
        yield s, Date, day+'T'+m[0]+':'+m[1]+':00' if day}}
    # summary
    if linenum > 0#, if non-empty
      yield log, Type, R[SIOC+'ChatLog']
      yield log, Date, mtime.iso8601
      yield log, Creator, channel
      yield log, To, network
      yield log, Title, basename.split('%23')[-1] # channel
      yield log, Size, linenum
    end
  rescue Exception => e
    puts [uri, e.class, e.message, e.backtrace[0..2].join("\n")].join " "
  end

  def triplrMail &b

    # read
    m = Mail.read node
    return unless m

    # identifier and storage
    id = m.message_id || m.resent_message_id || rand.to_s.sha1 # Message-ID
    e = MessagePath[id] # derive path from Message-ID
    canonicalLocation = e.R + '.msg' # storage location
    canonicalLocation.dir.mkdir # store to canonical location
    FileUtils.ln pathPOSIX, canonicalLocation.pathPOSIX unless canonicalLocation.e rescue nil
    yield e, DC+'identifier', id                # Message-ID in RDF
    yield e, DC+'source', self                  # originating-file pointer
    yield e, Type, R[SIOC+'MailMessage']        # RDF type-tag
    addrs = [] # addresses to index

    # From
    m.from.do{|f|f.justArray.map{|f|# source
                address = f.to_utf8.downcase # source address
                yield e, Creator, AddrPath[address].R # source triple
                addrs.push address # queue for indexing
              }}
    m[:from].do{|fr|fr.addrs.map{|a|yield e, Creator, a.display_name||a.name}} # source name

    # To
    %w{to cc bcc resent_to}.map{|p|      # header fields
      m.send(p).justArray.map{|to|       # recipient
        address = to.to_utf8.downcase    # recipient address
        yield e, To, AddrPath[address].R # recipient triple
        addrs.push address }}            # queue for indexing
    m['X-BeenThere'].justArray.map{|to|  # anti-loop addresses
      yield e, To, AddrPath[to.to_s].R } # recipient triple
    m['List-Id'].do{|name|                                          # list id
      yield e, To, name.decoded.sub(/<[^>]+>/,'').gsub(/[<>&]/,'')} # list name

    # Subject
    subject = nil
    m.subject.do{|s|
      subject = s.to_utf8.gsub(/\[[^\]]+\]/){|l|
        yield e, Label, l[1..-2]; nil} # emit []-wrapped tokens as RDF labels
      yield e, Title, subject}

    # Date
    if m.date
      date = m.date.to_time.utc
      dstr = date.iso8601
      yield e, Date, dstr
      yield e, Mtime, date.to_i
      # month-address index
      dpath = '/' + dstr[0..6].gsub('-','/') + '/addr/' # month
      addrs.map{|addr| # addresses
        user, domain = addr.split '@'
        apath = dpath + domain + '/' + user + '/' # address components
        if subject
          mpath = apath + (dstr[8..-1] + subject).gsub(/[^a-zA-Z0-9_]+/,'.')[0..96] # date + subject
          mpath = mpath + (mpath[-1] == '.' ? '' : '.')  + 'msg' # filetype
          mloc = mpath.R # storage reference
          mloc.dir.mkdir # index container
          FileUtils.ln pathPOSIX, mloc.pathPOSIX unless mloc.e rescue nil # link to index
        end}
    end

    # message references
    # map In-Reply-To -> sioc:reply_of, sioc:has_parent
    #     References  -> sioc:reply_of
    %w{in_reply_to references}.map{|ref|
      m.send(ref).do{|rs|
        # references
        rs.justArray.map{|r|
          target = R[MessagePath[r]]
          targetFile = target + '.msg'
          yield e, SIOC+'reply_of', target + '/'
          rev = target + '/' + id.sha1 + '.msg'
          rel = e.R + '/' + r.sha1 + '.msg'
          rel.dir.mkdir
          rev.dir.mkdir
          FileUtils.ln targetFile.pathPOSIX, rel.pathPOSIX if !rel.e && targetFile.e
          FileUtils.ln pathPOSIX, rev.pathPOSIX if !rev.e
        }}}
    # direct reference
    m.in_reply_to.do{|r|
      yield e, SIOC+'has_parent', R[MessagePath[r]]}

    # body
    htmlFiles, parts = m.all_parts.push(m).partition{|p|p.mime_type=='text/html'} # multipart message
    parts.select{|p|
      (!p.mime_type || p.mime_type == 'text/plain') && # find text parts
        Mail::Encodings.defined?(p.body.encoding)      # decoder must be defined to continue
    }.map{|p| # each text part
      body = H p.decoded.to_utf8.lines.to_a.map{|l| # decode line
        l = l.chomp # strip any remaining [\n\r]
        if qp = l.match(/^((\s*[>|]\s*)+)(.*)/) # quoted line
          depth = (qp[1].scan /[>|]/).size # count > occurrences
          if qp[3].empty? # drop empty-string lines while inside quoted portion
            nil
          else # wrap quotes in <span>
            indent = "<span name='quote#{depth}'>&gt;</span>" # indentation marker with depth label
            {_: :span, class: :quote, c: [indent * depth,' ', {_: :span, class: :quoted, c: qp[3].hrefs}]}
          end
        else # fresh line
          [l.hrefs{|p,o| # hypertextify
             yield e, p, o}] # emit found links as RDF
        end}.compact.intersperse("\n") # join lines
      yield e, Content, body} # emit body as RDF

    # attachments
    attache = -> {e.R.mkdir} # create container for attachments, called when needed
    htmlCount = 0
    htmlFiles.map{|p| # HTML
      html = attache[].child "#{htmlCount}.html" # file-path
      yield e, DC+'hasFormat', html              # point to HTML format
      html.writeFile p.decoded  if !html.e       # store to node
      htmlCount += 1 } # increment file-count
    parts.select{|p|p.mime_type=='message/rfc822'}.map{|m| # message(s)-in-message (i.e digests + forwards)
      f = attache[].child 'msg.' + rand.to_s.sha1 # file path
      f.writeFile m.body.decoded if !f.e # store message
      f.triplrMail &b} # recursion on message parts
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

  def fetchFeeds; uris.map(&:R).map(&:fetchFeed); nil end
  def fetchFeed # keep metadata for conditional-fetch
    updated = false
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
          updated = true
          body.writeFile resp
          ('file:'+body.pathPOSIX).R.indexFeed :format => :feed, :base_uri => uri
        end
      end
    rescue OpenURI::HTTPError => error
      msg = error.message
      puts [uri,msg].join("\t") unless msg.match(/304/) # print return-type unless OK or cache-hit (304)
    end
    updated ? self : nil
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
      content.css('a').map{|a| # absolutize URIs relative to remote base
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
            puts 'http:'+doc.stripDoc
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
          RDF::Writer.open(doc.pathPOSIX){|f|f << graph}
          FileUtils.ln doc.pathPOSIX, docP.pathPOSIX
          puts 'http:'+doc.stripDoc
        end
        true}}
    self
  rescue Exception => e
    puts uri, e.class, e.message , e.backtrace[0..2]
  end

  def feeds; (nokogiri.css 'link[rel=alternate]').map{|u|join u.attr :href} end

  module Feed # as RDF

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
            content.css('img').map{|i|yield s, Image, (i.attr 'src').R}
            content.css('a').map{|a|
              a.set_attribute 'href', (URI.join s, (a.attr 'href')) if a.has_attribute? 'href' rescue nil}
            content.css('span > a').map{|a|
              if a.inner_text=='[link]'
                link = (a.attr 'href').R
                yield s, DC+'link', link
                yield s, Image, link if %w{jpg png}.member? link.ext
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
                {DCe+'subject' => Title,
                 DCe+'type' => Type,
                 RSS+'title' => Title,
                 RSS+'description' => Content,
                 RSS+'encoded' => Content,
                 RSS+'modules/slash/comments' => SIOC+'num_replies',
                 RSS+'modules/content/encoded' => Content,
                 RSS+'category' => Label,
                 RSS+'source' => DC+'source',
                 Harvard+'author' => Creator,
                 Harvard+'subtitle' => Title,
                 Harvard+'WPID' => Label,
                 Harvard+'affiliation' => Creator,
                 Podcast+'keywords' => Label,
                 Podcast+'subtitle' => Title,
                 Podcast+'author' => Creator,
                 Atom+'displaycategories' => Label,
                 'http://newsoffice.mit.edu/ns/tags' => Label,
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
                    DCe+'date' => true,
                    Atom+'published' => true,
                    Atom+'updated' => true
                  }[p] ?
                  [s,Date,Time.parse(o).utc.iso8601] : [s,p,o])}
      end
      def rawTriples
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
            unless u.match /^http/ # resolve relative references
              u = (URI.join @base, u).to_s
            end
            resource = u.R
            if u.match commentRe
              yield u, R::Type, R[R::Post]
              yield u, R::To, R[resource.uri.match(commentRe).pre_match]
            else
              yield u, Type, R[SIOC+'BlogPost']
              blogs = [resource.join('/')]
              blogs.push @base.R.join('/') if @base.R.host != resource.host # reblog
              blogs.map{|blog| yield u, R::To, blog}
            end

            inner.scan(reAttach){|e| # media links
              e[1].match(reSrc).do{|url|
                rel = e[1].match reRel
                if rel
                  o = url[2].R
                  p = case o.ext.downcase
                      when 'jpg'
                        R::Image
                      when 'png'
                        R::Image
                      else
                        R::Atom + rel[1]
                      end
                  yield u, p, o
                end}}

            inner.scan(reElement){|e| # elements
              p = (x[e[0] && e[0].chop]||R::RSS) + e[1]                  # expand property-name
              if [Atom+'id',RSS+'link',RSS+'guid',Atom+'link'].member? p # custom element-type handlers
                # used in subject URI search
              elsif [Atom+'author', RSS+'author', RSS+'creator', DCe+'creator'].member? p # author
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
