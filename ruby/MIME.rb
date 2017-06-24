# coding: utf-8
class R

  def mime
    @mime ||=
      (ext = (File.extname(path)[1..-1]||'').downcase
       if node.directory?
         'inode/directory'
       elsif ext == 'msg' || File.basename(path).index('msg.')==0
         'message/rfc822'
       elsif ext == 'ttl'
         'text/turtle'
       elsif ext == 'u'
         'text/uri-list'
       elsif ext == 'log'
         'text/chatlog'
       elsif ext == 'md'
         'text/markdown'
       elsif %w{asc rb}.member? ext
         'text/plain'
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
    'audio/mpeg'           => [:triplrAudio],
    'audio/x-wav'           => [:triplrAudio],
    'audio/3gpp'           => [:triplrAudio],
    'image/gif'            => [:triplrImage],
    'image/png'            => [:triplrImage],
    'image/jpeg'           => [:triplrImage],
    'inode/directory'      => [:triplrContainer],
    'message/rfc822'       => [:triplrMail],
    'text/chatlog'         => [:triplrChatLog],
    'text/csv'             => [:triplrCSV,/,/],
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

  def isRDF; %w{html n3 rdf owl ttl}.member? ext end

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
    s = path
    s = '/'+s unless s[0] == '/'
    mt = mtime
    yield s, Type, R[Container]
    yield s, Mtime, mt.to_i
    yield s, Date, mt.iso8601
    # overview of contained
    graph = {}
    (R.load children).map{|u,r|
      if r[Title]
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

  def triplrFile
    s = path
    s = '/'+s unless s[0] == '/'
    yield s, Type, R[Stat+'File']
    mt = mtime
    yield s, Mtime, mt.to_i
    yield s, Date, mt.iso8601
    yield s, Size, size
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
        c: readFile.do{|r|
          enc ? r.force_encoding(enc).to_utf8 : r}.hrefs})
  end

  def triplrUriList
    uris.map{|u|yield u,Type,R[Resource]}
  end


  def uris
    (open pathPOSIX).readlines.map &:chomp
  end

  def triplrMarkdown
    s = stripDoc.uri
    yield s, Content,
          ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile) +
          H({_: :link, href: '/css/code.css', rel: :stylesheet, type: 'text/css'})
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

  def to_json *a
    {'uri' => uri}.to_json *a
  end

  def triplrImage &f
    yield uri, Type, R[Image]
  end
=begin
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
=end

  Icons = {
    'uri' => :id, Container => :dir, Content => :pencil, Date => :date, Label => :tag, Title => :title, Sound => :speaker, Image => :img, Size => :size, Mtime => :time, To => :user, Resource => :graph,
    DC+'hasFormat' => :file, Schema+'location' => :location, Stat+'File' => :file,
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
