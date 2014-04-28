%w{
cgi
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
redcarpet
shellwords}.map{|r|require r}

class R < RDF::URI

  FSbase = `pwd`.chomp ;  BaseLen = FSbase.size
  HTTP_URI = /\A(\/|http)[\S]+\Z/
  Doc = /\.(atom|e|html|json(ld)?|n3|nt|owl|rdf|ttl|txt)$/

  W3    = 'http://www.w3.org/'
  Purl  = 'http://purl.org/'
  FOAF  = "http://xmlns.com/foaf/0.1/"
  SIOC  = 'http://rdfs.org/sioc/ns#'
  SIOCt = 'http://rdfs.org/sioc/types#'
  Search   = 'http://sindice.com/vocab/search#'
  Audio    = 'http://www.semanticdesktop.org/ontologies/nid3/#'
  MIMEtype = 'http://www.iana.org/assignments/media-types/'
  Deri     = 'http://vocab.deri.ie/'
  DC       = Purl + 'dc/terms/'
  RSS      = Purl + 'rss/1.0/'
  Date     = DC   + 'date'
  Title    = DC   + 'title'
  Name     = SIOC + 'name'
  To       = SIOC + 'addressed_to'
  Creator  = SIOC + 'has_creator'
  Content  = SIOC + 'content'
  RDFns    = W3   + "1999/02/22-rdf-syntax-ns#"
  RDFs     = W3   + '2000/01/rdf-schema#'
# RDFns    = W3   + 'ns/rdf#'
# RDFs     = W3   + 'ns/rdfs#'
  EXIF     = W3   + '2003/12/exif/ns#'
  Atom     = W3   + '2005/Atom'
  HTTP     = W3   + '2011/http#'
  Header   = W3   + '2011/http-headers#'
  ACL      = W3   + 'ns/auth/acl#'
  LDP      = W3   + 'ns/ldp#'
  Stat     = W3   + 'ns/posix/stat#'
  Next     = LDP  + 'nextPage'
  Prev     = LDP  + 'prevPage'
  Type     = RDFns+ "type"
  COGS     = Deri + 'cogs#'
  CSV      = Deri + 'scsv#'
  HTML     = RDFns + "HTML"
  Label    = RDFs + 'label'

  Prefix={
    "dc" => DC,
    "foaf" => FOAF,
    "rdf" => RDFns,
    "rdfs" => RDFs,
    "sioc" => SIOC,
    "sioct" => SIOCt,
    "stat" => Stat,
  }

%w{
MIME
names
audio
blog
chan
csv
edit
facets
fs
GET
graph
HTML
HTTP
image
index
mail
man
news
POST
RDF
schema
search
text
time
WAC
who
}.map{|r|require_relative r}

  alias_method :maybeURI, :to_s
  alias_method :url, :to_s
  alias_method :uri, :to_s

end

class FalseClass
  def do; false end
end

class Hash
  def R; R.new uri end
  def uri; self["uri"]||"" end
  alias_method :url, :uri
  alias_method :maybeURI, :uri
end

class NilClass
  def do; nil end
end

class Object
  def id; self end
  def do; yield self end
  def maybeURI; nil end
end
