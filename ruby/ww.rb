%w{cgi csv date digest/sha1 fileutils json linkeddata mail open-uri pathname rack shellwords}.map{|r|require r}
class RDF::URI
  def R
    R.new to_s
  end
end
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

  FSbase = `pwd`.chomp ; BaseLen = FSbase.size
  HTTP_URI = /\A(\/|http)[\S]+\Z/

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
  SKOS     = W3   + '2004/02/skos/core#'
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

  Prefixes = {:ldp => RDF::URI(LDP),:rdf => RDF::URI(RDFns),:rdfs => RDF::URI(RDFs),:stat => RDF::URI(Stat)}

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

  # POSIX path mapping
  def justPath; (path || '/').R.setEnv(@r) end
  def child u; R[uri + (uri[-1] == '/' ? '' : '/') + u.to_s] end
  def dirname; (scheme ? scheme + ':' : '') + (host ? '//' + host : '') + (File.dirname path) end
  def dir; dirname.R end
  def children; node.c.map &:R end
  alias_method :c, :children
  def ext; (File.extname uri)[1..-1] || '' end
  def basename x = nil; path ? (x ? (File.basename path, x) : (File.basename path)) : '' end
  def pathPOSIX; FSbase + '/' +
                   (if h = host
                     'domain/' + h + stripHost
                    else
                     uri[0] == '/' ? uri[1..-1] : uri
                    end)
  end
  def node; Pathname.new pathPOSIX end
  def R.unPOSIX p, skip = R::BaseLen
    p[skip..-1].do{|p| R[ p.match(/^\/domain\/+(.*)/).do{|m|'//'+m[1]} || p]}
  end
  def stripHost; uri.split('//'+host,2)[1] end
  def stripDoc;  R[uri.sub /\.(e|ht|html|json|md|ttl|txt)$/,''].setEnv(@r) end
  def inside; node.expand_path.to_s.index(FSbase) == 0 end # jail path
  def sh; pathPOSIX.utf8.sh end # shell-escape path
  def exist?; node.exist? end
  alias_method :e, :exist?
  def file?; node.file? end
  alias_method :f, :file?
  def mtime; node.stat.mtime if e end
  alias_method :m, :mtime
  def size; node.size end
  Prefix = {"dc" => DC, "foaf" => FOAF, "ldp" => LDP, "rdf" => RDFns, "rdfs" => RDFs, "sioc" => SIOC, "stat" => Stat}
  def expand;   uri.expand.R end

  %w{MIME JSON HTML HTTP message search text}.map{|r|require_relative r}

end
