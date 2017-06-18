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
  def triples &f
    map{|s,resource|
      resource.map{|p,o|
        o.justArray.map{|o|yield s,p,o} if p != 'uri'}}
  end
  def types; self[R::Type].justArray.select{|t|t.respond_to? :uri}.map &:uri end
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
  Container = W3  + 'ns/ldp#Container'

  Icons = {
    'uri' => :id,
    Container => :dir,
    Content => :pencil,
    Date => :date,
    Label => :tag,
    Title => :title,
    Sound => :speaker,
    Image => :img,
    Size => :size,
    Mtime => :time,
    To => :user,
    Resource => :graph,
    DC+'hasFormat' => :file,
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
    SIOC+'has_container' => :dir,
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
  Abstract = {} # RDF type

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

  def pathPOSIX; (host ? ('domain/' + host) : '.') + path end
  def R.unPOSIX p; R[p.match(/domain\/+(.*)/).do{|m|'//'+m[1]} || p] end
  def node; Pathname.new pathPOSIX end
  def justPath; (path || '/').R.setEnv(@r) end
  def child u; R[uri + (uri[-1] == '/' ? '' : '/') + u.to_s] end
  def dirname; (scheme ? scheme + ':' : '') + (host ? '//' + host : '') + (File.dirname path) end
  def dir; dirname.R end
  def children; node.children.map &:R end
  def glob; (Pathname.glob pathPOSIX).map &:R end
  def ext; (File.extname uri)[1..-1] || '' end
  def basename x = nil; path ? (x ? (File.basename path, x) : (File.basename path)) : '' end
  def stripDoc;  R[uri.sub /\.(e|ht|html|json|md|ttl|txt)$/,''].setEnv(@r) end
  def inside; node.expand_path.to_s.index(FSbase) == 0 end # jail path to server-root
  def sh; pathPOSIX.utf8.sh end # shell-escape path
  def exist?; node.exist? end
  def file?; node.file? end
  def mtime; node.stat.mtime if e end
  def size; node.size end
  alias_method :e, :exist?
  alias_method :m, :mtime

  %w{MIME HTML HTTP message search}.map{|r|require_relative r}

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

