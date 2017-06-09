# coding: utf-8
class R

  def mime
    @mime ||=
      (p = node.realpath # dereference link(s)
       unless p
         nil
       else
         t = ((File.extname p)[1..-1] || '').downcase
         if p.directory?
           "inode/directory"
         elsif (File.basename p).index('msg.')==0
           "message/rfc822"
         elsif MIME[t]
           MIME[t]
         elsif Rack::Mime::MIME_TYPES['.'+t]
           Rack::Mime::MIME_TYPES['.'+t]
         else
           puts "unknown MIME #{p}"
           `file --mime-type -b #{Shellwords.escape p.to_s}`.chomp
         end
       end )
  end

  MIME={
    '3gpp' => 'audio/3gpp',
    'aif' => 'audio/aif',
    'asc' => 'text/plain',
    'atom' => 'application/atom+xml',
    'avi' => 'video/avi',
    'bz2' => 'application/bzip2',
    'e' => 'application/json+rdf',
    'eml' => 'message/rfc822',
    'coffee' => 'text/plain',
    'conf' => 'text/plain',
    'css' => 'text/css',
    'csv' => 'text/csv',
    'eps' => 'application/postscript',
    'flv' => 'video/flv',
    'for' => 'application/fortran',
    'gemspec' => 'application/ruby',
    'gif' => 'image/gif',
    'go' => 'text/x-c',
    'gz' => 'application/gzip',
    'haml' => 'application/haml',
    'hs' => 'application/haskell',
    'html' => 'text/html',
    'ico' => 'image/x-ico',
    'ini' => 'application/ini',
    'jpeg' => 'image/jpeg',
    'jpg' => 'image/jpeg',
    'jpg-large' => 'image/jpeg',
    'js' => 'application/javascript',
    'json' => 'application/json',
    'jsonld' => 'application/ld+json',
    'log' => 'text/log',
    'm4a' => 'audio/mp4',
    'markdown' => 'text/markdown',
    'md' => 'text/markdown',
    'mkv' => 'video/matroska',
    'mp3' => 'audio/mpeg',
    'mp4' => 'video/mp4',
    'mpg' => 'video/mpg',
    'n3' => 'text/n3',
    'nfo' => 'text/nfo',
    'nt' => 'text/ntriples',
    'org' => 'application/org',
    'owl' => 'application/rdf+xml',
    'pdf' => 'application/pdf',
    'php' => 'application/php',
    'pl' => 'application/perl',
    'pm' => 'application/perl',
    'png' => 'image/png',
    'ps' => 'application/postscript',
    'py' => 'application/python',
    'rb' => 'application/ruby',
    'rev' => 'text/uri-list+index',
    'ru' => 'application/ruby',
    'rdf' => 'application/rdf+xml',
    'rss' => 'application/atom+xml',
    'rtf' => 'text/rtf',
    'ssv' => 'text/semicolon-separated-values',
    't' => 'application/perl',
    'tex' => 'text/x-tex',
    'tsv' => 'text/tab-separated-values',
    'ttf' => 'font/truetype',
    'ttl' => 'text/turtle',
    'txt' => 'text/plain',
    'u' => 'text/uri-list',
    'url' => 'text/plain',
    'wav' => 'audio/wav',
    'webp' => 'image/webp',
    'wmv' => 'video/wmv',
    'xlsx' => 'application/excel',
    'xml' => 'application/atom+xml',
    'zip' => 'application/zip',
  }
  
  MIMEsource={
    'application/atom+xml' => [:triplrFeed],
    'application/org'      => [:triplrOrg],
    'application/bzip2'    => [:triplrArchive],
    'application/gzip'     => [:triplrArchive],
    'application/zip'     => [:triplrArchive],
    'audio/mpeg'           => [:triplrAudio],
    'audio/3gpp'           => [:triplrAudio],
    'image'                => [:triplrImage],
    'inode/directory'      => [:triplrContainer],
    'message/rfc822'       => [:triplrMailIndexer],
    'text/csv'             => [:triplrCSV,/,/],
    'text/log'             => [:triplrIRC],
    'text/man'             => [:triplrMan],
    'text/markdown'        => [:triplrMarkdown],
    'text/n3'              => [:triplrRDF,:n3],
    'text/nfo'             => [:triplrHref,'cp437'],
    'text/plain'           => [:triplrHref],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values'=>[:triplrCSV,/;/],
    'text/tab-separated-values'=>[:triplrCSV,/\t/],
    'text/turtle'          => [:triplrRDF,:turtle],
    'text/tw'              => [:triplrTwUsers],
    'text/uri-list'        => [:triplrUriList],
    'text/x-tex'           => [:triplrTeX],
  }

  def triplrMIME &b
    mime.do{|mime|
      (MIMEsource[mime]||                # exact match
       MIMEsource[mime.split(/\//)[0]]|| # category
       :triplrFile).do{|s|               # nothing found, basic file metadata
        send *s,&b }}
  end

  def triplrContainer
    dir = path || ''
    dir += '/' unless dir[-1] == '/'
    yield dir, Type, R[Container]
    mt = mtime
    yield dir, Mtime, mt.to_i
    yield dir, Date, mt.iso8601
    children = c
    yield dir, Size, children.size
  end

  def triplrFile
    yield uri, Type, R[Stat+'File']
    mt = mtime
    yield uri, Mtime, mt.to_i
    yield uri, Date, mt.iso8601
    yield uri, Size, size
  end

  def triplrArchive
    yield uri, Type, R[Stat+'CompressedFile']
    mt = mtime
    yield uri, Mtime, mt.to_i
    yield uri, Date, mt.iso8601
    yield uri, Size, size
  end

  def triplrRDF f
    RDF::Reader.open(pathPOSIX, :format => f, :base_uri => stripDoc){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s,[RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}}
  end

  def triplrAudio &f
    yield uri, Type, R[Sound]
  end
  # scan for HTTP URIs in plain-text. example:
  # as you can see in the demo (https://suchlike) and find full source at https://stuffshere.com.
  # these decisions were made:
  # opening ( required for ) match, as referencing URLs inside () seems more common than URLs containing unmatched ()s [citation needed]
  # and , and . only match mid-URI to allow usage of URLs as words in sentences ending in a period.
  # <> wrapped URIs are supported
  Href = /(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/
  def triplrHref enc=nil
    id = stripDoc.uri
    yield id, Type, R[SIOC+'TextFile']
    yield id, Content,
    H({_: :pre, style: 'white-space: pre-wrap',
        c: open(pathPOSIX).read.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs}) if f
  end

  def triplrUriList
    open(pathPOSIX).readlines.map{|l|
      yield l.chomp, Type, R[Resource] }
  end

  def uris
    graph.keys.select{|u|u.match /^http/}.map &:R
  end

  def triplrMarkdown
    s = stripDoc.uri
    yield s, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(r) + H({_: :link, href: '/css/code.css', rel: :stylesheet, type: MIME[:css]})
  end

  def triplrOrg
    require 'org-ruby'
    yield stripDoc.uri, Content, Orgmode::Parser.new(r).to_html
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

  Abstract[SIOC+'TextFile'] = -> graph, subgraph, env {
    subgraph.map{|id,data|
      graph[id][DC+'hasFormat'] = R[id+'.html']
      graph[id][Content] = graph[id][Content].justArray.map{|c|c.lines[0..8].join}}}

  # graph as JSON:
  # {subjURI(str) => {predURI(str) => [objectA..]}}

  # tripleStream -> Graph
  def fromStream m,*i
    send(*i) do |s,p,o|
      m[s] = {'uri' => s} unless m[s].class == Hash 
      m[s][p] ||= []
      m[s][p].push o unless m[s][p].class != Array || m[s][p].member?(o)
    end
    m
  end

  # normalize file references to RDF-file references, transcode as needed
  def justRDF pass = %w{e} # whitelisted formats. by default our native JSON format optimized for speed
    if pass.member? node.realpath.do{|p|p.extname[1..-1]} # already RDF
      self # return
    else # non RDF, transcode
      h = uri.sha1
      doc = R['/cache/RDF/'+h[0..2]+'/'+h[3..-1]+'.e'].setEnv @r
      doc.w fromStream({},:triplrMIME),true unless doc.e && doc.m > m # cache check
      doc
    end
  end
  
  # file -> Graph
  def loadGraph graph
    return unless e
    justRDF.do{|f| # maybe transcode to RDF
      ((f.r true)||{}). # read JSON file
        triples{|s,p,o| # add triples to graph
        graph[s] ||= {'uri' => s}
        graph[s][p] = (graph[s][p]||[]).justArray.push o
      }}
    graph
  end

  # files -> Graph
  def graph graph = {}
    documents.map{|d|d.loadGraph graph}
    graph
  end

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  Render['application/json'] = -> graph,_ { graph.to_json }

  Abstract[Sound] = -> graph, g, e {graph['#audio'] = {Type => R[Sound+'Player']}} # add player

  GET['thumbnail'] = -> e {
    thumb = nil
    path = e.path.sub /^.thumbnail/, ''
    i = R['//' + e.host + path]
    i = R[path] unless i.file? && i.size > 0
    if i.file? && i.size > 0
      if i.ext.match /SVG/i
        thumb = i
      else
        thumb = i.dir.child '.' + i.basename + '.png'
        if !thumb.e
          if i.mime.match(/^video/)
            `ffmpegthumbnailer -s 360 -i #{i.sh} -o #{thumb.sh}`
          else
            `gm convert #{i.ext.match(/^jpg/) ? 'jpg:' : ''}#{i.sh} -thumbnail "360x360" #{thumb.sh}`
          end
        end
      end
      thumb && thumb.e && thumb.setEnv(e.env).fileGET || e.notfound
    else
      e.notfound
    end}

  def triplrImage &f
    yield uri, Type, R[Image]
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
        @graph.triples{|s,p,o|
          fn.call RDF::Statement.new(
                    @base.join(s),
                    RDF::URI(p),
                    o.class==Hash ? @base.join(o['uri']) : (l = RDF::Literal o
                                                         l.datatype=RDF.XMLLiteral if p == Content
                                                         l)
                  )}
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
