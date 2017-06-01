# coding: utf-8
%w{cgi csv date digest/sha1 fileutils json linkeddata mail open-uri pathname rack rdf redcarpet shellwords}.map{|r|require r}

def R uri
  R.new uri
end
class Array
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
  def justArray; self end
end
class FalseClass
  def do; false end
end
class Hash
  def R; R.new self["uri"] end
  def uri; self["uri"] end
end
class NilClass
  def do; nil end
  def justArray; [] end
end
class Object
  def id; self end
  def do; yield self end
  def justArray; [self] end
  def to_time
    [Time, DateTime].member?(self.class) ? self : Time.parse(self)
  end
end

class R < RDF::URI
  alias_method :uri, :to_s

  # URI constants
  W3    = 'http://www.w3.org/'
  Purl  = 'http://purl.org/'
  FOAF  = "http://xmlns.com/foaf/0.1/"
  DC    = Purl + 'dc/terms/'
  SIOC  = 'http://rdfs.org/sioc/ns#'
  Schema = 'http://schema.org/'
  Sound    = Purl + 'ontology/mo/Sound'
  Image    = DC + 'Image'
  RSS      = Purl + 'rss/1.0/'
  Date     = DC   + 'date'
  Title    = DC   + 'title'
  Re       = SIOC + 'reply_of'
  Post     = SIOC + 'Post'
  To       = SIOC + 'addressed_to'
  From     = SIOC + 'has_creator'
  Creator  = SIOC + 'has_creator'
  Content  = SIOC + 'content'
  LDP      = W3   + 'ns/ldp#'
  Stat     = W3   + 'ns/posix/stat#'
  CSVns    = W3   + 'ns/csv#'
  RDFns    = W3   + '1999/02/22-rdf-syntax-ns#'
  RDFs     = W3   + '2000/01/rdf-schema#'
  Atom     = W3   + '2005/Atom#'
  Type     = RDFns + 'type'
  Resource = RDFs + 'Resource'
  Label    = RDFs + 'label'
  Size     = Stat + 'size'
  Mtime    = Stat + 'mtime'
  Container= LDP + 'Container'

  Icons = {
    'uri' => :id,
    Container => :dir,
    Content => :pencil,
    Date => :date,
    Label => :tag,
    Title => :title,
    Sound => :speaker,
    FOAF+'Person' => :person,
    Image => :img,
    LDP+'contains' => :container,
    Size => :size,
    Mtime => :time,
    To => :user,
    Resource => :graph,
    DC+'hasFormat' => :file,
    Atom+'self' => :graph,
    Atom+'alternate' => :file,
    Atom+'edit' => :pencil,
    Atom+'replies' => :comments,
    RSS+'link' => :link,
    RSS+'guid' => :id,
    RSS+'comments' => :comments,
    Schema+'location' => :location,
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
    SIOC+'has_discussion' => :comments,
    SIOC+'Thread' => :openenvelope,
    SIOC+'Post' => :newspaper,
    SIOC+'MailMessage' => :envelope,
    SIOC+'has_parent' => :reply,
    SIOC+'reply_to' => :reply,
    Stat+'File' => :file,
    Stat+'CompressedFile' => :archive,
    "http://rdfs.org/resume-rdf/cv.rdfs#Entry" => :hands,
  }

  # lambda tables
  GET = {}
  Abstract = {} # summarize
  Render = {}   # MIME renderer
  View = {}     # HTML template

  # constructors
  def R uri = nil
    uri ? (R.new uri) : self
  end
  def R.[] uri; R.new uri end

  # equality / comparison
  def ==  u; to_s == u.to_s end
  def <=> c; to_s <=> c.to_s end

  # append
  def + u; R uri + u.to_s end
  alias_method :a, :+

  FSbase = `pwd`.chomp
  BaseLen = FSbase.size

  # POSIX path acrobatics
  def pathPOSIX; FSbase + '/' +
                   (if h = host
                     'domain/' + h + stripHost
                    else
                     uri[0] == '/' ? uri[1..-1] : uri
                    end)
  end
  def R.unPOSIX p, skip = R::BaseLen; p[skip..-1].do{|p| R[p.match(/^\/domain\/+(.*)/).do{|m|'//'+m[1]} || p]} end
  def node; Pathname.new pathPOSIX end
  def justPath; (path || '/').R.setEnv(@r) end
  def child u; R[uri + (uri[-1] == '/' ? '' : '/') + u.to_s] end
  def dirname; (scheme ? scheme + ':' : '') + (host ? '//' + host : '') + (File.dirname path) end
  def dir; dirname.R end
  def children; node.c.map &:R end
  def glob; (Pathname.glob pathPOSIX).map &:R end
  def ext; (File.extname uri)[1..-1] || '' end
  def basename x = nil; path ? (x ? (File.basename path, x) : (File.basename path)) : '' end
  def stripHost; host ? uri.split('//'+host,2)[1] : uri end
  def stripDoc;  R[uri.sub /\.(e|ht|html|json|md|ttl|txt)$/,''].setEnv(@r) end
  def inside; node.expand_path.to_s.index(FSbase) == 0 end # jail path to server-root
  def sh; pathPOSIX.utf8.sh end # shell-escape path
  def exist?; node.exist? end
  def file?; node.file? end
  def mtime; node.stat.mtime if e end
  def size; node.size end
  alias_method :c, :children
  alias_method :f, :file?
  alias_method :e, :exist?
  alias_method :m, :mtime

  %w{MIME HTML HTTP graph message search}.map{|r|require_relative r}

  # scan for HTTP URIs in plain-text. example:
  # as you can see in the demo (https://suchlike) and find full source at https://stuffshere.com.
  # these decisions were made:
  # opening ( required for ) match, as referencing URLs inside () seems more common than URLs containing unmatched ()s
  # and , and . only match mid-URI to allow substitution of URLs with words in sentences. <> wrapped URIs are supported
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
    yield s, Type, R[SIOC+'MarkdownContent']
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

end

class RDF::URI
  def R
    R.new to_s
  end
end

class String
  def R; R.new self end # cast to URI
  # text to HTML, emit URIs as RDF
  def hrefs &b
    pre,link,post = self.partition R::Href
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escape URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escape pre-match
      (link.empty? && '' || '<a id="t' + rand.to_s.sha1[0..3] + '" href="' + u + '">' + # hyperlink
       (if u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) # image?
        yield(R::Image,u.R) if b # emit image as triple
        "<img src='#{u}'/>"           # inline image
       else
         yield(R::DC+'link',u.R) if b # emit hypertexted link
         u.sub(/^https?.../,'')       # text
        end) + '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # process post-match tail
  rescue Exception => x
    puts [x.class,x.message,x.backtrace].join("\n")
    ""
  end
  def sha1; Digest::SHA1.hexdigest self end
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
