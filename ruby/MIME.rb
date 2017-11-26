# coding: utf-8
class R

  # name prefix -> MIME
  MIMEprefix = {
    'authors' => 'text/plain',
    'changelog' => 'text/plain',
    'contributors' => 'text/plain',
    'copying' => 'text/plain',
    'install' => 'text/x-shellscript',
    'license' => 'text/plain',
    'readme' => 'text/markdown',
    'todo' => 'text/plain',
    'unlicense' => 'text/plain',
    'msg' => 'message/rfc822',
  }

  # name suffix -> MIME
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
    'go' => 'application/go',
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
    'sh' => 'text/x-shellscript',
    'terminfo' => 'application/config',
    'tmp' => 'application/octet-stream',
    'ttl' => 'text/turtle',
    'u' => 'text/uri-list',
    'woff' => 'application/font',
    'yaml' => 'text/plain',
  }

  # MIME -> Triplr
  Triplr = {
    'application/config'   => [:triplrDataFile],
    'application/font'      => [:triplrFile],
    'application/go'   => [:triplrSourceCode],
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
    'text/x-php'           => [:triplrSourceCode],
    'text/x-python'        => [:triplrSourceCode],
    'text/x-script.ruby'   => [:triplrSourceCode],
    'text/x-script.python' => [:triplrSourceCode],
    'text/x-shellscript'   => [:triplrFile],
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

  # RDF type -> icon name (icon name to font mapping in icons.css)
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
    DC+'link' => :chain,
    DC+'cache' => :chain,
    Schema+'Person' => :user,
    Schema+'location' => :location,
    Stat+'File' => :file,
    Stat+'Archive' => :archive,
    Stat+'HTMLFile' => :html,
    Stat+'WordDocument' => :word,
    Stat+'DataFile' => :tree,
    Stat+'TextFile' => :textfile,
    Stat+'width' => :width,
    Stat+'height' => :height,
    Stat+'container' => :dir,
    Stat+'contains' => :dir,
    SIOC+'BlogPost' => :pencil,
    SIOC+'ChatLog' => :comments,
    SIOC+'Discussion' => :comments,
    SIOC+'InstantMessage' => :comment,
    SIOC+'MicroblogPost' => :newspaper,
    SIOC+'WikiArticle' => :pencil,
    SIOC+'Usergroup' => :group,
    SIOC+'SourceCode' => :code,
    SIOC+'Tweet' => :bird,
    SIOC+'has_creator' => :user,
    SIOC+'user_agent' => :mailer,
    SIOC+'has_discussion' => :comments,
    SIOC+'Thread' => :openenvelope,
    SIOC+'Post' => :newspaper,
    SIOC+'MailMessage' => :envelope,
    W3+'2000/01/rdf-schema#Resource' => :node,
  }

  # file -> MIME
  def mime
    @mime ||= # memoize
      (name = path || ''
       prefix = ((File.basename name).split('.')[0]||'').downcase
       suffix = ((File.extname name)[1..-1]||'').downcase
       if node.directory? # container
         'inode/directory'
       elsif MIMEprefix[prefix] # prefix mapping
         MIMEprefix[prefix]
       elsif MIMEsuffix[suffix] # suffix mapping
         MIMEsuffix[suffix]
       elsif Rack::Mime::MIME_TYPES['.'+suffix] # suffix mapping (Rack fallback)
         Rack::Mime::MIME_TYPES['.'+suffix]
       else
         puts "#{pathPOSIX} unmapped MIME, sniffing content (SLOW)"
         `file --mime-type -b #{Shellwords.escape pathPOSIX.to_s}`.chomp
       end)
  end

  def R.tokens str; str ? str.scan(/[\w]+/).map(&:downcase).uniq : [] end
  Writable = %w{application/atom+xml text/html}
  def isRDF; %w{atom n3 rdf owl ttl}.member? ext end
  def toRDF; isRDF ? self : transcode end       # R -> R
  def to_json *a; {'uri' => uri}.to_json *a end # R -> Hash

  def load set # load Non-RDF + RDF to URI-indexed tree
    graph = RDF::Graph.new # graph
    g = {}                 # tree
    rdf,nonRDF = set.partition &:isRDF #partition on file type
    # load RDF
    rdf.map{|n|graph.load n.pathPOSIX, :base_uri => n}
    graph.each_triple{|s,p,o| # each triple
      s = s.to_s; p = p.to_s # subject, predicate
      o = [RDF::Node, RDF::URI, R].member?(o.class) ? o.R : o.value # object
      g[s] ||= {'uri'=>s} # new resource
      g[s][p] ||= []
      g[s][p].push o unless g[s][p].member? o} # RDF to tree
    # load nonRDF
    nonRDF.map{|n|
      n.transcode.do{|transcode| # transcode to RDF
        JSON.parse(transcode.readFile).map{|s,re| # subject
          re.map{|p,o| # predicate, objects
            o.justArray.map{|o| # object
              o = o.R if o.class==Hash
              g[s] ||= {'uri'=>s} # new resource
              g[s][p] ||= []; g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}}} # RDF to tree
    if q.has_key?('du') && path != '/' # DU: container storage-size attribute
      set.select{|d|d.node.directory?}.-([self]).map{|node|
        g[node.path+'/']||={}
        g[node.path+'/'][Size] = node.du}
    elsif (q.has_key?('f')||q.has_key?('q')) && path!='/' # FIND/GREP: container match-count attribute
      set.map{|r|
        bin = r.dirname + '/'
        g[bin] ||= {'uri' => bin, Type => Container}
        g[bin][Size] = 0 if !g[bin][Size] || g[bin][Size].class==Array
        g[bin][Size] += 1}
    end
    g
  end

  def loadRDF set # load RDF to RDF::Graph
    g = RDF::Graph.new; set.map{|n|g.load n.toRDF.pathPOSIX, :base_uri => n.stripDoc}
    g
  end

  def transcode # non-RDF to RDF using triplrs
    return self if ext == 'e'
    hash = node.stat.ino.to_s.sha2
    doc = R['/.cache/'+hash[0..2]+'/'+hash[3..-1]+'.e'].setEnv @r
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
  rescue Exception => e
    puts uri, e.class, e.message
  end

  def nokogiri; Nokogiri::HTML.parse (open uri).read end
  def triplrArchive &f; yield uri, Type, R[Stat+'Archive']; triplrFile &f end
  def triplrAudio &f;   yield uri, Type, R[Sound]; triplrFile &f end
  def triplrHTML &f;    yield uri, Type, R[Stat+'HTMLFile']; triplrFile &f end
  def triplrDataFile &f; yield uri, Type, R[Stat+'DataFile']; triplrFile &f end
  def triplrSourceCode &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -f html #{sh}`; triplrFile &f end
  def triplrTeX;        yield stripDoc.uri, Content, `cat #{sh} | tth -r` end
  def triplrRTF          &f; triplrWord :catdoc,        &f end
  def triplrWordDoc      &f; triplrWord :antiword,      &f end
  def triplrWordXML      &f; triplrWord :docx2txt, '-', &f end
  def triplrOpenDocument &f; triplrWord :odt2txt,       &f end
  def triplrUriList; uris.map{|u|yield u, Type, R[W3+'2000/01/rdf-schema#Resource']} end
  def uris; open(pathPOSIX).readlines.map &:chomp end

  # POSIX map
  def R.fromPOSIX p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R rescue '/'.R end
  def + u; R[uri + u.to_s].setEnv @r end
  def <=> c; to_s <=> c.to_s end
  def ==  u; to_s == u.to_s end
  def basename; File.basename (path||'') end
  def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map{|c|c.R.setEnv @r} end
  def dir; dirname.R end
  def dirname; File.dirname path end
  def exist?; node.exist? end
  def ext; (File.extname uri)[1..-1] || '' end
  def du; `du -s #{sh}| cut -f 1`.chomp.to_i end
  def find p; (p && !p.empty?) ? `find #{sh} -ipath #{('*'+p+'*').sh} | head -n 1024`.lines.map{|p|R.fromPOSIX p.chomp} : [] end
  def glob; (Pathname.glob pathPOSIX).map{|p|p.R.setEnv @r}.do{|g|g.empty? ? nil : g} end
  def label; fragment || (path && basename != '/' && (URI.unescape basename)) || host || '' end
  def ln x,y;   FileUtils.ln   x.node.expand_path, y.node.expand_path end
  def ln_s x,y; FileUtils.ln_s x.node.expand_path, y.node.expand_path end
  def match p; to_s.match p end
  def mkdir; FileUtils.mkdir_p pathPOSIX unless exist?; self end
  def mtime; node.stat.mtime end
  def node; @node ||= (Pathname.new pathPOSIX) end
  def pathPOSIX; @path ||= (URI.unescape(path[0]=='/' ? '.' + path : path)) end
  def parts; path ? path.split('/') : [] end
  def readFile; File.open(pathPOSIX).read end
  def shellPath; pathPOSIX.utf8.sh end
  def size; node.size rescue 0 end
  def stripDoc; R[uri.sub /\.(e|html|json|log|md|msg|ttl|txt)$/,''].setEnv(@r) end
  def writeFile o; dir.mkdir; File.open(pathPOSIX,'w'){|f|f << o}; self end

  alias_method :e, :exist?
  alias_method :m, :mtime
  alias_method :sh, :shellPath
  alias_method :uri, :to_s

  def triplrFile
    s = path
    size.do{|sz|yield s, Size, sz}
    yield s, Title, basename
    mtime.do{|mt|
      yield s, Mtime, mt.to_i
      yield s, Date, mt.iso8601}
  end

  def triplrContainer
    s = path
    s = s + '/' unless s[-1] == '/'
    yield s, Type, R[Container]
    yield s, Size, children.size
    yield s, Title, basename+'/'
    mtime.do{|mt|
      yield s, Mtime, mt.to_i
      yield s, Date, mt.iso8601}
  end

  def triplrImage &f
    yield uri, Type, R[Image]
    w,h = Dimensions.dimensions pathPOSIX
    yield uri, Stat+'width', w
    yield uri, Stat+'height', h
    triplrFile &f
  end

  def triplrWord conv, out='', &f
    triplrFile &f
    yield uri, Type, R[Stat+'WordDocument']
    yield uri, Content, '<pre>' +
                        `#{conv} #{sh} #{out}` +
                        '</pre>'
  end

  def triplrText enc=nil, &f
    doc = stripDoc.uri
    yield doc, Type, R[Stat+'TextFile']
    mtime.do{|mt|
      yield doc, Date, mt.iso8601}
    yield doc, DC+'hasFormat', self
    yield doc, Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: readFile.do{|r| enc ? r.force_encoding(enc).to_utf8 : r}.hrefs})
  rescue Exception => e
    puts uri, e.class, e.message
  end

  def triplrMarkdown
    doc = stripDoc.uri
    yield doc, Type, R[Stat+'TextFile']
    yield doc, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile)
    mtime.do{|mt|yield doc, Date, mt.iso8601}
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

  def triplrChatLog &f
    linenum = -1
    base = stripDoc
    dir = base.dir
    log = base.uri
    basename = base.basename
    channel = dir + '/' + basename
    network = dir + '/' + basename.split('%23')[0] + '*'
    day = dir.uri.match(/\/(\d{4}\/\d{2}\/\d{2})/).do{|d|d[1].gsub('/','-')}
    readFile.lines.map{|l|
      l.scan(/(\d\d)(\d\d)(\d\d)[\s+@]*([^\(\s]+)[\S]* (.*)/){|m|
        s = base + '#l' + (linenum += 1).to_s
        yield s, Type, R[SIOC+'InstantMessage']
        yield s, Label, m[3]
        yield s, Creator, R['#'+m[3]]
        yield s, To, channel
        yield s, Content, m[4].hrefs{|p, o|
          yield log, p, o
          yield s, p, o
        }
        yield s, Date, day+'T'+m[0]+':'+m[1]+':'+m[2] if day}}
    if linenum > 0 # summarize at log-URI
      yield log, Type, R[SIOC+'ChatLog']
      yield log, Date, mtime.iso8601
      yield log, Creator, channel
      yield log, To, network
      yield log, Title, basename.split('%23')[-1] # channel
      yield log, Size, linenum
    end
  rescue Exception => e
    puts uri, e.class, e.message
  end

  MessageURI = -> id { h=id.sha2; ['', 'msg', h[0], h[1], h[2], id.gsub(/[^a-zA-Z0-9]+/,'.')[0..96], '#this'].join('/').R}
  def triplrMail &b
    m = Mail.read node; return unless m # open message-file
    id = m.message_id || m.resent_message_id || rand.to_s.sha2 # Message-ID
    resource = MessageURI[id]; e = resource.uri                # Message URI
    srcDir = resource.path.R; srcDir.mkdir # container
    srcFile = srcDir + 'this.msg'          # found location
    ln self, srcFile unless srcFile.e rescue nil # canonical location
    yield e, DC+'identifier', id         # pre-web identifier
    yield e, DC+'cache', self + '*' # source file
    yield e, Type, R[SIOC+'MailMessage'] # RDF type

    # From
    from = []
    m.from.do{|f|f.justArray.map{|f|from.push f.to_utf8.downcase if f}} # queue for indexing
    m[:from].do{|fr|
      fr.addrs.map{|a|yield e, Creator, a.display_name||a.name} if fr.respond_to? :addrs} # creator name
    m['X-Mailer'].do{|m|yield e, SIOC+'user_agent', m.to_s}

    # To
    to = []
    %w{to cc bcc resent_to}.map{|p|      # recipient fields
      m.send(p).justArray.map{|r|        # recipient
        to.push r.to_utf8.downcase }}    # queue for indexing
    m['X-BeenThere'].justArray.map{|r|to.push r.to_s} # anti-loop recipient
    m['List-Id'].do{|name|yield e, To, name.decoded.sub(/<[^>]+>/,'').gsub(/[<>&]/,'')} # mailinglist name

    # Subject
    subject = nil
    m.subject.do{|s|
      subject = s.to_utf8.gsub(/\[[^\]]+\]/){|l|
        yield e, Label, l[1..-2]; nil} # emit []-wrapped tokens as RDF labels
      yield e, Title, subject}

    # Date
    date = m.date || Time.now rescue Time.now
    date = date.to_time.utc
    dstr = date.iso8601
    yield e, Date, dstr
    dpath = '/' + dstr[0..6].gsub('-','/') + '/msg/' # month
    [*from,*to].map{|addr| # addresses
      user, domain = addr.split '@'
      if user && domain
        apath = dpath + domain + '/' + user # address
        yield e, (from.member? addr) ? Creator : To, R[apath+'#'+user]
        if subject
          slug = R.tokens(subject).join('.')[0..63]
          mpath = apath + '.' + dstr[8..-1].gsub(/[^0-9]+/,'.') + slug # time & subject
          mpath = mpath + (mpath[-1] == '.' ? '' : '.')  + 'msg' # file-type extension
          mdir = '../.mail/' + domain + '/' # maildir
          %w{cur new tmp}.map{|c| R[mdir + c].mkdir} # maildir container
          mloc = R[mdir + 'cur/' + id.sha2 + '.msg'] # maildir entry
          iloc = mpath.R # index entry
          [iloc,mloc].map{|loc| loc.dir.mkdir # container
            ln self, loc unless loc.e rescue nil} # link
        end
      end
    }

    %w{in_reply_to references}.map{|ref|
      m.send(ref).do{|rs|
        rs.justArray.map{|r|
          dest = MessageURI[r]
          yield e, SIOC+'reply_of', dest
          destDir = dest.path.R; destDir.mkdir; destFile = destDir+'this.msg'
          # bidirectional reference link
          rev = destDir + id.sha2 + '.msg'
          rel = srcDir + r.sha2 + '.msg'
          if !rel.e # link missing
            if destFile.e # exists, create link
              ln destFile, rel rescue nil
            else # point to message anyway in case it appears
              ln_s destFile, rel rescue nil
            end
          end
          ln srcFile, rev if !rev.e rescue nil}}}
    # part handling
    htmlFiles, parts = m.all_parts.push(m).partition{|p|p.mime_type=='text/html'}
    htmlCount = 0
    htmlFiles.map{|p| # HTML file
      html = srcDir + "#{htmlCount}.html"  # file location
      yield e, DC+'hasFormat', html        # file pointer
      html.writeFile p.decoded  if !html.e # store HTML email
      htmlCount += 1 } # increment count
    parts.select{|p|
      (!p.mime_type || p.mime_type == 'text/plain') && # text parts
        Mail::Encodings.defined?(p.body.encoding)      # decodable?
    }.map{|p|
      yield e, Content, (H p.decoded.to_utf8.lines.to_a.map{|l| # split lines
        l = l.chomp # strip any remaining [\n\r]
        if qp = l.match(/^((\s*[>|]\s*)+)(.*)/) # quoted line
          depth = (qp[1].scan /[>|]/).size # > count
          if qp[3].empty? # drop blank quotes
            nil
          else # wrap quotes in <span>
            indent = "<span name='quote#{depth}'>&gt;</span>"
            {_: :span, class: :quote,
             c: [indent * depth,' ',
                 {_: :span, class: :quoted, c: qp[3].gsub('@','').hrefs{|p,o|yield e, p, o}}]}
          end
        else # fresh line
          [l.gsub(/(\w+)@(\w+)/,'\2\1').hrefs{|p,o|yield e, p, o}]
        end}.compact.intersperse("\n"))} # join lines
    parts.select{|p|p.mime_type=='message/rfc822'}.map{|m|
      content = m.body.decoded                   # decode message-part
      f = srcDir + content.sha2 + '.inlined.msg' # message location
      f.writeFile content if !f.e                # store message
      f.triplrMail &b}                           # recursion on message-part
    m.attachments.select{|p|Mail::Encodings.defined?(p.body.encoding)}.map{|p|
      name = p.filename.do{|f|f.to_utf8.do{|f|!f.empty? && f}} ||                           # explicit name
             (rand.to_s.sha2 + (Rack::Mime::MIME_TYPES.invert[p.mime_type] || '.bin').to_s) # generated name
      file = srcDir + name                     # file location
      file.writeFile p.body.decoded if !file.e # store
      yield e, SIOC+'attachment', file         # file pointer
      if p.main_type=='image'                  # image attachments
        yield e, Image, file                   # image link represented in RDF
        yield e, Content,                      # image link represented in HTML
          H({_: :a, href: file.uri, c: [{_: :img, src: file.uri}, p.filename]}) # render HTML
      end }
  end

  def fetchFeed
    head = {} # request header
    cache = R['/.cache/'+uri.sha2+'/'] # storage
    etag = cache + 'etag'      # cache etag URI
    priorEtag = nil            # cache etag value
    mtime = cache + 'mtime'    # cache mtime URI
    priorMtime = nil           # cache mtime value
    body = cache + 'body.atom' # cache body URI
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
        etag.writeFile curEtag if curEtag && !curEtag.empty? && curEtag != priorEtag # new ETag value
        mtime.writeFile curMtime.iso8601 if curMtime != priorMtime # new Last-Modified value
        resp = response.read
        unless body.e && body.readFile == resp
          body.writeFile resp # new cached body
          ('file:'+body.pathPOSIX).R.indexFeed :format => :feed, :base_uri => uri # run indexer
        end
      end
    rescue OpenURI::HTTPError => error
      msg = error.message
      puts [uri,msg].join("\t") unless msg.match(/304/)
    end
  rescue Exception => e
    puts uri, e.class, e.message
  end
  def fetchFeeds; uris.map(&:R).map &:fetchFeed end
  def feeds; (nokogiri.css 'link[rel=alternate]').map{|u|join u.attr :href} end
  alias_method :getFeed, :fetchFeed

  def indexFeed options = {}
    g = RDF::Repository.load self, options
    g.each_graph.map{|graph|
      graph.query(RDF::Query::Pattern.new(:s,R[R::Date],:o)).first_value.do{|t| # find timestamp
        time = t.gsub(/[-T]/,'/').sub(':','/').sub /(.00.00|Z)$/, ''
        slug = (graph.name.to_s.sub(/https?:\/\//,'.').gsub(/[\W_]/,'..').sub(/\d{12,}/,'')+'.').gsub(/\.+/,'.')[0..127].sub(/\.$/,'')
        doc =  R["/#{time}#{slug}.ttl"]
        unless doc.e
          doc.dir.mkdir
          cacheBase = doc.stripDoc
          graph << RDF::Statement.new(graph.name, R[DC+'cache'], cacheBase)
          RDF::Writer.open(doc.pathPOSIX){|f|f << graph}
          puts cacheBase
        end
        true}}
    self
  rescue Exception => e
    puts uri, e.class, e.message
  end

  # Reader for JSON-cache format
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
                                                              l))} unless p=='uri'}}
      end
      def each_triple &block; each_statement{|s| block.call *s.to_triple} end
    end
  end

  # Reader for Atom and RSS
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
      def each_triple &block; each_statement{|s| block.call *s.to_triple} end
      def each_statement &fn # triples flow (left ← right)
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
          if p==Content && o.class==String
            content = Nokogiri::HTML.fragment o
            content.css('img').map{|i|
              (i.attr 'src').do{|src|
                yield s, Image, src.R }}
            content.css('a').map{|a|
              (a.attr 'href').do{|href|
                link = s.R.join href
                a.set_attribute 'href', link
                yield s, DC+'link', link
                yield s, Image, link if %w{gif jpg png webp}.member? link.R.ext.downcase
              }}
            yield s, p, content.to_xhtml
          else
            yield s, p, o
          end
        }
      end
      def normalizePredicates *f
        send(*f){|s,p,o|
          yield s,
                {Atom+'content' => Content,
                 Atom+'displaycategories' => Label,
                 Atom+'enclosure' => SIOC+'attachment',
                 Atom+'summary' => Content,
                 Atom+'title' => Title,
                 DCe+'subject' => Title,
                 DCe+'type' => Type,
                 Podcast+'author' => Creator,
                 Podcast+'keywords' => Label,
                 Podcast+'subtitle' => Title,
                 RSS+'category' => Label,
                 RSS+'description' => Content,
                 RSS+'encoded' => Content,
                 RSS+'modules/content/encoded' => Content,
                 RSS+'modules/slash/comments' => SIOC+'num_replies',
                 RSS+'source' => DC+'source',
                 RSS+'title' => Title,
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
        # XML namespaces
        x = {}
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
          u = (attrs.do{|a|a.match(reRDF)} || inner.match(reLink) || inner.match(reLinkCData) || inner.match(reLinkHref) || inner.match(reLinkRel) || inner.match(reId)).do{|s|s[1]}
          if u
            u = (URI.join @base, u).to_s unless u.match /^http/
            resource = u.R
            yield u, Type, R[SIOC+'BlogPost']
            blogs = [resource.join('/')]
            blogs.push @base.R.join('/') if @base.R.host != resource.host
            blogs.map{|blog| yield u, R::To, blog}
            # links
            inner.scan(reAttach){|e|
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
            # XML elements
            inner.scan(reElement){|e|
              p = (x[e[0] && e[0].chop]||R::RSS) + e[1] # namespaced attribute-names
              if [Atom+'id',RSS+'link',RSS+'guid',Atom+'link'].member? p
                # used in subject URI search
              elsif [Atom+'author', RSS+'author', RSS+'creator', DCe+'creator'].member? p
                uri = e[3].match /<uri>([^<]+)</
                name = e[3].match /<name>([^<]+)</
                yield u, Creator, e[3].do{|o|o.match(/\A(\/|http)[\S]+\Z/) ? o.R : o } unless name||uri
                yield u, Creator, name[1] if name
                yield u, Creator, uri[1].R if uri
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

  FEED = -> d,e {
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

class String
  def R; R.new self end
  # scan for HTTP URIs in string. example:
  # demo on the site (https://demohere) and source-code at https://sourcehere.
  # [,.] only match mid-URI, opening ( required for ) capture, <> wrapping is stripped
  def hrefs &b
    pre,link,post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escaped URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escaped pre-match
      (link.empty? && '' || '<a href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # image RDF
        "<img src='#{u}'/>"      # inline image
       else
         yield(R::DC+'link',u.R) if b # link RDF
         u.sub(/^https?.../,'')  # inline text
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # recursion on post-capture tail
  end
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
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
