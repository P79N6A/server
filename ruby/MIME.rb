# coding: utf-8
class R

  MIMEprefix = {
    'capfile' => 'text/plain',
    'dockerfile' => 'text/plain',
    'gemfile' => 'application/ruby',
    'install' => 'text/plain',
    'license' => 'text/plain',
    'msg' => 'message/rfc822',
    'rakefile' => 'application/ruby',
    'readme' => 'text/plain',
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
       elsif MIMEsuffix[suffix] # suffix mapping (built-in)
         MIMEsuffix[suffix]
       elsif Rack::Mime::MIME_TYPES['.'+suffix] # suffix mapping (Rack)
         Rack::Mime::MIME_TYPES['.'+suffix]
       else # FILE(1) sniff content
         puts "WARNING unknown MIME of #{pathPOSIX}, sniffing (SLOW)"
         `file --mime-type -b #{Shellwords.escape pathPOSIX.to_s}`.chomp
       end)
  end

  def isRDF; %w{n3 rdf owl ttl}.member? ext end

  def toRDF; isRDF ? self : toJSON end

  def toJSON
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

  def triplrContainer
    s = path || ''
    s += '/' unless s[-1] == '/'
    s = '/'+s unless s[0] == '/'
    mt = mtime
    yield s, Type, R[Container]
    yield s, Mtime, mt.to_i
    yield s, Date, mt.iso8601
    # overview of contained
    graph = {}
    leafNodes = children.select{|e|!e.node.directory?}
    (R.load leafNodes).map{|u,r|
      types = r.types
      unless types.member?(SIOC+'InstantMessage') || types.member?(SIOC+'Tweet')
        [DC+'link', SIOC+'attachment', DC+'hasFormat', Content].map{|p|r.delete p}
        graph[u] = r
      end
      if r[Image]
        graph[s] ||= {}
        graph[s][Title] ||= ''
        graph[s][Image] ||= []
        graph[s][Image].concat r[Image]
      end
    }
    yield s, Content, (H TabularView[graph,self,true])
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

  def triplrArchive &f
    yield uri, Type, R[Stat+'CompressedFile']
    triplrFile false,&f
  end

  def triplrImage &f
    yield uri, Type, R[Image]
    triplrFile false,&f
  end

  GalleryView = -> graph,e {
    images = graph.keys.grep /(jpg|png)$/i
    {_: :html,
     c: [{_: :head,
          c: [{_: :style, c: R['/css/photoswipe.css'].readFile},{_: :style, c: R['/css/default-skin/default-skin.css'].readFile},{_: :script, c: R['/js/photoswipe.min.js'].readFile},{_: :script, c: R['/js/photoswipe-ui-default.min.js'].readFile},
             #{_: :link, rel: :stylesheet, href: '/css/photoswipe.css'}, {_: :link, rel: :stylesheet, href: '/css/default-skin/default-skin.css'}, {_: :script, src: '/js/photoswipe.min.js'}, {_: :script, src: '/js/photoswipe-ui-default.min.js'},
          ]},
         {_: :body,
          c: [images.map{|i|
                {_: :a, href: i, c: {_: :img, src: i+'?thumb', style: 'height:20em'}}},
              %q{<!-- Root element of PhotoSwipe. Must have class pswp. --> <div class="pswp" tabindex="-1" role="dialog" aria-hidden="true"> <!-- Background of PhotoSwipe.          It's a separate element as animating opacity is faster than rgba(). --> <div class="pswp__bg"></div> <!-- Slides wrapper with overflow:hidden. --> <div class="pswp__scroll-wrap"> <!-- Container that holds slides.             PhotoSwipe keeps only 3 of them in the DOM to save memory.             Don't modify these 3 pswp__item elements, data is added later on. --> <div class="pswp__container"> <div class="pswp__item"></div> <div class="pswp__item"></div> <div class="pswp__item"></div> </div> <!-- Default (PhotoSwipeUI_Default) interface on top of sliding area. Can be changed. --> <div class="pswp__ui pswp__ui--hidden"> <div class="pswp__top-bar"> <!--  Controls are self-explanatory. Order can be changed. --> <div class="pswp__counter"></div> <button class="pswp__button pswp__button--close" title="Close (Esc)"></button> <button class="pswp__button pswp__button--share" title="Share"></button> <button class="pswp__button pswp__button--fs" title="Toggle fullscreen"></button> <button class="pswp__button pswp__button--zoom" title="Zoom in/out"></button> <!-- Preloader demo http://codepen.io/dimsemenov/pen/yyBWoR --> <!-- element will get class pswp__preloader--active when preloader is running --> <div class="pswp__preloader"> <div class="pswp__preloader__icn"> <div class="pswp__preloader__cut"> <div class="pswp__preloader__donut"></div> </div> </div> </div> </div> <div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap"> <div class="pswp__share-tooltip"></div> </div> <button class="pswp__button pswp__button--arrow--left" title="Previous (arrow left)"> </button> <button class="pswp__button pswp__button--arrow--right" title="Next (arrow right)"> </button> <div class="pswp__caption"> <div class="pswp__caption__center"></div> </div> </div> </div> </div>},
              {_: :script, c: "
      var items = #{images.map{|k|{src: k, w: graph[k][Stat+'width'].justArray[0].to_i, h: graph[k][Stat+'height'].justArray[0].to_i}}.to_json};
      var gallery = new PhotoSwipe( document.querySelectorAll('.pswp')[0], PhotoSwipeUI_Default, items, {index: 0});
      gallery.init();
"}]}]}}
  
  def triplrAudio &f
    yield uri, Type, R[Sound]
    triplrFile false,&f
  end

  def triplrHTML &f
    yield uri, Type, R[Stat+'HTMLFile']
    triplrFile false,&f
  end

  # scan for HTTP URIs in plain-text. example:
  # as you can see in the demo (https://suchlike) and find full source at https://stuffshere.com.
  # these decisions were made:
  # opening ( required for ) match, as referencing URLs inside () seems more common than URLs containing unmatched ()s [citation needed]
  # and , and . only match mid-URI to allow usage of URLs as words in sentences ending in a period.
  # <> wrapped URIs are supported
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

  def triplrUriList
    uris.map{|u|yield u,Type,R[Resource]}
  end


  def uris
    (open pathPOSIX).readlines.map &:chomp
  end

  def triplrMarkdown
    s = stripDoc.uri
    yield s, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile)
  end

  def triplrOrg
    require 'org-ruby'
    yield stripDoc.uri, Content, Orgmode::Parser.new(r).to_html
  end

  def triplrSourceCode &f
    yield uri, Type, R[SIOC+'SourceCode']
    yield uri, Content, `pygmentize -f html #{sh}`
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

  def triplrRTF
    yield stripDoc.uri, Content, `which catdoc && catdoc #{sh}`.hrefs
  end

  def triplrTeX
    yield stripDoc.uri, Content, `cat #{sh} | tth -r`
  end

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  Icons = {
    'uri' => :id, Container => :dir, Content => :pencil, Date => :date, Label => :tag, Title => :title, Sound => :speaker, Image => :img, Size => :size, Mtime => :time, To => :user, Resource => :graph,
    DC+'hasFormat' => :file, Schema+'location' => :location, Stat+'File' => :file, Stat+'CompressedFile' => :archive, Stat+'HTMLFile' => :html,
    SIOC+'BlogPost' => :pencil,
    SIOC+'Discussion' => :comments,
    SIOC+'InstantMessage' => :comment,
    SIOC+'MicroblogPost' => :newspaper,
    SIOC+'WikiArticle' => :pencil,
    SIOC+'Tweet' => :tweet,
    SIOC+'Usergroup' => :group,
    SIOC+'SourceCode' => :code,
    SIOC+'TextFile' => :file,
    SIOC+'has_creator' => :user,
    SIOC+'has_container' => :dir,
    SIOC+'has_discussion' => :comments,
    SIOC+'Thread' => :openenvelope,
    SIOC+'Post' => :newspaper,
    SIOC+'MailMessage' => :envelope,
    SIOC+'has_parent' => :reply,
    SIOC+'reply_to' => :reply}

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

      def each_triple &block
        each_statement{|s| block.call *s.to_triple}
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
