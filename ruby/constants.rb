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
shellwords}.map{|r|require r}

class R < RDF::URI

  FSbase = `pwd`.chomp ;  BaseLen = FSbase.size

  W3    = 'http://www.w3.org/'
  Purl  = 'http://purl.org/'
  FOAF  = "http://xmlns.com/foaf/0.1/"
  SIOC  = 'http://rdfs.org/sioc/ns#'
  SIOCt = 'http://rdfs.org/sioc/types#'
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
  LDP      = W3   + 'ns/ldp#'
  Stat     = W3   + 'ns/posix/stat#'
  Next     = LDP  + 'nextPage'
  Prev     = LDP  + 'prevPage'
  Type     = RDFns+ "type"
  COGS     = Deri + 'cogs#'
  CSV      = Deri + 'scsv#'
  HTML     = RDFns + "HTML"
  Label    = RDFs + 'label'

  Search   = 'http://sindice.com/vocab/search#'
  Audio    = 'http://www.semanticdesktop.org/ontologies/nid3/#'
  Render   = 'http://whats-your.name/www#RenderMIME/'

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
board
csv
edit
facets
feed
fs
GET
HTTP
graph
html
image
index
mail
man
microblog
POST
RDF
search
text
time
who
}.map{|r|require_relative r}

end
