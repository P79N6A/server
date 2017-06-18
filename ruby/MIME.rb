# coding: utf-8
class R

  def mime
    @mime ||=
      (ext = ((File.extname path)[1..-1] || '').downcase
       if node.directory?
         'inode/directory'
       elsif (File.basename path).index('msg.') == 0
         'message/rfc822'
       elsif ext == 'ttl'
         'text/turtle'
       elsif Rack::Mime::MIME_TYPES['.'+ext]
         Rack::Mime::MIME_TYPES['.'+ext]
       else
         puts "#{pathPOSIX} of unknown MIME, sniffing content (WARNING SLOW)"
         `file --mime-type -b #{Shellwords.escape pathPOSIX.to_s}`.chomp
       end)
  end
  
  Triplr = {
    'application/atom+xml' => [:triplrFeed],
    'application/org'      => [:triplrOrg],
    'application/bzip2'    => [:triplrArchive],
    'application/gzip'     => [:triplrArchive],
    'application/zip'     => [:triplrArchive],
    'audio/mpeg'           => [:triplrAudio],
    'audio/3gpp'           => [:triplrAudio],
    'image/png'            => [:triplrImage],
    'image/jpeg'           => [:triplrImage],
    'inode/directory'      => [:triplrContainer],
    'message/rfc822'       => [:triplrMailIndexer],
    'text/csv'             => [:triplrCSV,/,/],
    'text/log'             => [:triplrIRC],
    'text/man'             => [:triplrMan],
    'text/markdown'        => [:triplrMarkdown],
    'text/nfo'             => [:triplrHref,'cp437'],
    'text/plain'           => [:triplrHref],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values'=>[:triplrCSV,/;/],
    'text/tab-separated-values'=>[:triplrCSV,/\t/],
    'text/uri-list'        => [:triplrUriList],
    'text/x-tex'           => [:triplrTeX],
  }

  def toRDF
    return self if %w{e html n3 rdf owl ttl}.member?(ext)
    hash = uri.sha1
    doc = R['/cache/RDF/'+hash[0..2]+'/'+hash[3..-1]+'.e'].setEnv @r
    unless doc.e && doc.m > m
      graph = {}
      triplr = Triplr[mime]
      puts "no triplr for #{uri} #{mime}" unless triplr
      send(*triplr){|s,p,o|
        graph[s] ||= {'uri' => s}
        graph[s][p] ||= []
        graph[s][p].push o} if triplr
      doc.writeFile graph.to_json
    end
    doc
  end

  def triplrContainer
    s = path
    s = s+'/' unless s[-1] == '/'
    s = '/'+s unless s[0] == '/'
    mt = mtime
    yield s, Type, R[Container]
    yield s, Mtime, mt.to_i
    yield s, Date, mt.iso8601
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

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  Abstract[Sound] = -> graph, g, e {graph['#audio'] = {Type => R[Sound+'Player']}} # add player

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
