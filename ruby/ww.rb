
def watch f
  R::Watch[f] = File.mtime f # add source to reload-on-change watchlist
  puts 'developing '+f
end

%w{
cgi
csv
date
digest/sha1
fileutils
json
linkeddata
mail
open-uri
pathname
rack
shellwords}.map{|r|
  print r, ' '
  require r
}

print "\n"

class RDF::URI
  def R
    R.new to_s
  end
end

def R uri
  R.new uri
end

class Array
  def cr; intersperse "\n" end
  def head; self[0] end
  def tail; self[1..-1] end
  def h; join.h end
  def intersperse i
    inject([]){|a,b|a << b << i}[0..-2]
  end
  def justArray; self end
end

class Fixnum
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class Float
  def max i; i > self ? self : i end
  def min i; i < self ? self : i end
end

class FalseClass
  def do; false end
end

class Hash
  def R; R.new uri end
  def uri; self["uri"] end
  alias_method :maybeURI, :uri
end

class NilClass
  def do; nil end
  def justArray; [] end
end

class Object
  def id; self end
  def do; yield self end
  def maybeURI; nil end
  def justArray; [self] end
  def time?
    (self.class == Time) || (self.class == DateTime)
  end
  def to_time
    time? ? self : Time.parse(self)
  end
end

class R < RDF::URI

  alias_method :uri, :to_s
  alias_method :maybeURI, :uri

  FSbase = `pwd`.chomp ; BaseLen = FSbase.size
  HTTP_URI = /\A(\/|http)[\S]+\Z/

  ## URI constants

  W3    = 'http://www.w3.org/'
  Purl  = 'http://purl.org/'
  FOAF  = "http://xmlns.com/foaf/0.1/"
  RO    = 'http://rdfs.org/'
  DC    = Purl + 'dc/terms/'
  SIOC  = RO + 'sioc/ns#'
  VOID  = RO + 'ns/void#'
  MIMEtype = 'http://www.iana.org/assignments/media-types/'
  Schema   = 'http://schema.org/'
  Profile  = FOAF + 'PersonalProfileDocument'
  Mu       = Purl + 'ontology/mo/'
  Sound    = Mu + 'Sound'
  Image    = DC + 'Image'
  RSS      = Purl + 'rss/1.0/'
  Date     = DC   + 'date'
  Title    = DC   + 'title'
  User     = SIOC + 'UserAccount'
  Post     = SIOC + 'Post'
  To       = SIOC + 'addressed_to'
  Creator  = SIOC + 'has_creator'
  Content  = SIOC + 'content'
  Forum    = SIOC + 'Forum'
  BlogPost = SIOC + 'BlogPost'
  Wiki     = SIOC + 'Wiki'
  Blog     = SIOC + 'Blog'
  WikiArticle = SIOC + 'WikiArticle'
  Auth     = W3   + 'ns/auth/'
  ACL      = Auth + 'acl#'
  Key      = Auth + 'cert#RSAPublicKey'
  LDP      = W3   + 'ns/ldp#'
  Stat     = W3   + 'ns/posix/stat#'
  CSVns    = W3   + 'ns/csv#'
  RDFns    = W3   + '1999/02/22-rdf-syntax-ns#'
  RDFs     = W3   + '2000/01/rdf-schema#'
  OWL      = W3   + '2002/07/owl#'
  SKOS     = W3   + '2004/02/skos/core#'
  Atom     = W3   + '2005/Atom#'
  HTTP     = W3   + '2011/http#'
  Header   = W3   + '2011/http-headers#'
  Next     = LDP  + 'nextPage'
  Prev     = LDP  + 'prevPage'
  RDFClass = RDFs + 'Class'
  Type     = RDFns + 'type'
  Property = RDFns + 'Property'
  HTML     = RDFns + 'HTML'
  Resource = RDFs + 'Resource'
  Label    = RDFs + 'label'
  Size     = Stat + 'size'
  Mtime    = Stat + 'mtime'
  Container= LDP + 'Container'
  Search   = 'http://sindice.com/vocab/search#'

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
    Resource => :graph,
    Forum => :comments,
    WikiArticle => :pencil,
    DC+'hasFormat' => :file,
    Atom+'self' => :graph,
    Atom+'alternate' => :file,
    Atom+'edit' => :pencil,
    Atom+'replies' => :comments,
    RSS+'link' => :link,
    RSS+'guid' => :id,
    RSS+'comments' => :comments,
    SIOC+'BlogPost' => :pencil,
    SIOC+'Discussion' => :comments,
    SIOC+'InstantMessage' => :comment,
    SIOC+'MicroblogPost' => :newspaper,
    SIOC+'Tweet' => :tweet,
    SIOC+'Usergroup' => :group,
    SIOC+'SourceCode' => :code,
    SIOC+'TextFile' => :file,
    SIOC+'channel' => :exchange,
    SIOC+'has_creator' => :user,
    SIOC+'has_container' => :up,
    SIOC+'has_discussion' => :comments,
    SIOC+'Thread' => :openenvelope,
    SIOC+'Post' => :newspaper,
    SIOC+'MailMessage' => :envelope,
    SIOC+'has_parent' => :reply,
    SIOC+'reply_to' => :reply,
    Stat+'File' => :file,
    Stat+'CompressedFile' => :archive,
  }

  Prefix={ # String -> String
    "dc" => DC,
    "foaf" => FOAF,
    "ldp" => LDP,
    "rdf" => RDFns,
    "rdfs" => RDFs,
    "sioc" => SIOC,
    "stat" => Stat,
  }

  Prefixes = { # Symbol -> URI
    :http => RDF::URI(HTTP),
    :ldp => RDF::URI(LDP),
    :rdf => RDF::URI(RDFns),
    :rdfs => RDF::URI(RDFs),
    :stat => RDF::URI(Stat),
  }

  ## user-customize tables
  GET = {}         # GET handler
  FileSet = {}     # files in GET
  ResourceSet = {} # resources in GET
  Filter = {}      # graph-transform (whole graph)
  Abstract = {}    # graph-transform (RDF-type constrained subgraph)
  Render = {}      # MIME renderer
  View = {}       # HTML template
  Watch = {}       # source-files to check for changes

%w{
MIME
names
JSON
HTML
HTTP
message
search
text
}.map{|r|require_relative r}

require './local.rb' if R['local.rb'].exist? # local configuration

RDFsuffixes = %w{e html jsonld n3 nt owl rdf ttl}
  NonRDF = %w{application/atom+xml application/json text/html text/uri-list}

  def R.schemas # list schemas
    table = {}
    open('http://prefix.cc/popular/all.file.txt').each_line{|l|
      unless l.match /^#/ # skip
        prefix, uri = l.split(/\t/)
        table[prefix] = uri.chomp
      end}
    table
   end

   def R.cacheSchemas # cache all the schemas
     R.schemas.map{|prefix,uri| uri.R.cacheSchema prefix }
   end

   # Ruby: R('http://schema.org/docs/schema_org_rdfa.html').cacheSchema 'schema'
   # sh: R http://schema.org/docs/schema_org_rdfa.html cacheSchema schema
   def cacheSchema prefix
    short = R['schema'].child(prefix).ttl
    if !short.e # already fetched
      terms = RDF::Graph.load uri
      triples = terms.size
      if triples > 0
        puts "#{uri} :: #{triples} triples"
        ttl.w terms.dump :ttl
        ttl.ln_s short
      end
    end
   end

end
