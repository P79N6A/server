class E

  FSbase = `pwd`.chomp ;  BaseLen = FSbase.size
  S      = /\._/ # data path-separator

  W3    = 'http://www.w3.org/'
  Purl  = 'http://purl.org/'
  FOAF  = "http://xmlns.com/foaf/0.1/"
  SIOC  = 'http://rdfs.org/sioc/ns#'
  SIOCt = 'http://rdfs.org/sioc/types#'
  MIMEtype = 'http://www.iana.org/assignments/media-types/'
  DIG      = 'http://dig.csail.mit.edu/'
  Deri     = 'http://vocab.deri.ie/'
  DC       = Purl + 'dc/terms/'
  Date     = DC   + 'date'
  Title    = DC   + 'title'
  Name     = SIOC + 'name'
  To       = SIOC + 'addressed_to'
  Creator  = SIOC + 'has_creator'
  Content  = SIOC + 'content'
  XHV      = W3   + '1999/xhtml/vocab#'
  RDFns    = W3   + "1999/02/22-rdf-syntax-ns#"
  RDFs     = W3   + '2000/01/rdf-schema#'
# RDFns    = W3   + 'ns/rdf#'
# RDFs     = W3   + 'ns/rdfs#'
  EXIF     = W3   + '2003/12/exif/ns#'
  WF       = W3   + '2005/01/wf/flow#'
  HTTP     = W3   + '2011/http#'
  Header   = W3   + '2011/http-headers#'
  LDP      = W3   + 'ns/ldp#'
  Next     = LDP  + 'nextPage'
  Prev     = LDP  + 'prevPage'
  Posix    = W3   + 'ns/posix/'
  Type     = RDFns+ "type"
  PAC      = DIG  + '2008/PAC/ontology/pac#'
  COGS     = Deri + 'cogs#'
  CSV      = Deri + 'scsv#'
  HTML     = RDFns + "HTML"
  Label    = RDFs + 'label'
  Stat     = Posix + 'stat#'
  Search   = 'http://sindice.com/vocab/search#'
  Audio    = 'http://www.semanticdesktop.org/ontologies/nid3/#'
  Edit     = 'http://buzzword.org.uk/rdf/personal-link-types#edit'
  Render   = 'http://whats-your.name/www#RenderMIME/'

  Prefix={
    "dc" => DC,
    "foaf" => FOAF,
    "rdf" => W3 + "ns/rdf#" ,
    "rdfs" => RDFs,
    "sioc" => SIOC,
    "stat" => Stat,
  }

end
