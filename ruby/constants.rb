%w{
cgi
csv
date
digest/sha1
fileutils
json
linkeddata
mail
nokogiri
open-uri
pathname
rack
shellwords}.map{|r|require r}

class R < RDF::URI

  FSbase = `pwd`.chomp ;  BaseLen = FSbase.size
  HTTP_URI = /\A(\/|http)[\S]+\Z/

  Apache = ENV['apache']
  Nginx  = ENV['nginx']

  W3    = 'http://www.w3.org/'
  Purl  = 'http://purl.org/'
  FOAF  = "http://xmlns.com/foaf/0.1/"
  RO    = 'http://rdfs.org/'
  SIOC  = RO + 'sioc/ns#'
  SIOCt = RO + 'sioc/types#'
  VOID  = RO + 'ns/void#'
  Search   = 'http://sindice.com/vocab/search#'
  Audio    = 'http://www.semanticdesktop.org/ontologies/nid3/#'
  Edit     = 'http://buzzword.org.uk/rdf/personal-link-types#edit'
  MIMEtype = 'http://www.iana.org/assignments/media-types/'
  Schema   = 'http://schema.org/'
  DC       = Purl + 'dc/terms/'
  RSS      = Purl + 'rss/1.0/'
  Date     = DC   + 'date'
  Title    = DC   + 'title'
  Name     = SIOC + 'name'
  To       = SIOC + 'addressed_to'
  Creator  = SIOC + 'has_creator'
  Content  = SIOC + 'content'
  ACL      = W3   + 'ns/auth/acl#'
  LDP      = W3   + 'ns/ldp#'
  Stat     = W3   + 'ns/posix/stat#'
  CSVns    = W3   + 'ns/csv#'
  RDFns    = W3   + '1999/02/22-rdf-syntax-ns#'
  RDFs     = W3   + '2000/01/rdf-schema#'
  EXIF     = W3   + '2003/12/exif/ns#'
  SKOS     = W3   + '2004/02/skos/core#'
  Atom     = W3   + '2005/Atom'
  HTTP     = W3   + '2011/http#'
  Header   = W3   + '2011/http-headers#'
  Next     = LDP  + 'nextPage'
  Prev     = LDP  + 'prevPage'
  Type     = RDFns+ 'type'
  HTML     = RDFns + 'HTML'
  Label    = RDFs + 'label'
  Container = LDP + 'Container'

  Prefix={
    "dc" => DC,
    "foaf" => FOAF,
    "ldp" => LDP,
    "rdf" => RDFns,
    "rdfs" => RDFs,
    "sioc" => SIOC,
    "sioct" => SIOCt,
    "stat" => Stat,
  }

  Prefixes = { # for RDF::Writer
    :http => RDF::URI(HTTP),
    :ldp => RDF::URI(LDP),
    :rdf => RDF::URI(RDFns),
    :rdfs => RDF::URI(RDFs),
    :sioct => RDF::URI(SIOCt),
    :stat => RDF::URI(Stat),
  }

  FileSet = {}
  ResourceSet = {}
  Abstract = {}
  Render = {}
  ViewA = {}
  ViewGroup = {}
  JSONview = {}
  Watch = {}
  GET = {}
  POST = {}

  Stats = {agent: {},
           error: {},
           format: {},
           host: {},
           status: {}}

  GREP_DIRS = []

%w{
MIME
names
acl
chat
container
csv
DELETE
facets
fs
GET
graph
HEAD
HTML
HTTP
JSON
image
index
mail
man
news
OPTIONS
PATCH
POST
PUT
schema
search
text
uid
vis
wiki
}.map{|r|require_relative r}

  NonRDF = %w{application/atom+xml application/json text/html text/uri-list}
  Resource = R[RDFs+'Resource']

  alias_method :uri, :to_s
  alias_method :maybeURI, :uri

end

class FalseClass
  def do; false end
end

class Hash
  def R; R.new uri end
  def uri; self["uri"]||"" end
  alias_method :maybeURI, :uri
end

class NilClass
  def do; nil end
end

class Object
  def id; self end
  def do; yield self end
  def maybeURI; nil end
  def time?
    (self.class == Time) || (self.class == DateTime)
  end
  def to_time
    time? ? self : Time.parse(self)
  rescue
    nil
  end
end
