#watch __FILE__
class E

  FSbase   = `pwd`.chomp ;  BaseLen = FSbase.size
  Prefix   = '/@' # prefix for non-local and non-HTTP URIs
  S        = '<>' # tree-root basename

  # URIs
  W3    = 'http://www.w3.org/'
  Purl  = 'http://purl.org/'
  FOAF  = "http://xmlns.com/foaf/0.1/"
  SIOC  = 'http://rdfs.org/sioc/ns#'
  SIOCt = 'http://rdfs.org/sioc/types#'
  MIMEtype = 'http://www.iana.org/assignments/media-types/'
  DC       = Purl + 'dc/terms/'
  Date     = DC   + 'date'
  Modified = DC   + 'modified'
  Title    = DC   + 'title'
  Name     = FOAF + 'name'
  To       = SIOC + 'addressed_to'
  Creator  = SIOC + 'has_creator'
  Content  = SIOC + 'content'
  Type     = W3   + "1999/02/22-rdf-syntax-ns#type"
  RDFs     = W3   + '2000/01/rdf-schema#'
  HTTP     = W3   + '2011/http#'
  Header   = W3   + '2011/http-headers#'
  Posix    = W3   + 'ns/posix/'
  Stat     = Posix + 'stat#'
  Label    = RDFs + 'label'
  EXIF     = 'http://www.w3.org/2003/12/exif/ns#'
  Audio    = 'http://www.semanticdesktop.org/ontologies/nid3/#'
  Edit     = 'http://buzzword.org.uk/rdf/personal-link-types#edit'

  # file-name extension -> MIME type
  MIME={
    aif: 'audio/aif',
    ans: 'text/ansi',
    atom: 'application/atom+xml',
    avi: 'video/avi',
    e: 'application/json+rdf',
    coffee: 'text/plain',
    css: 'text/css',
    csv: 'text/comma-separated-values',
    doc: 'application/word',
    flv: 'video/flv',
    for: 'application/fortran',
    gemspec: 'application/ruby',
    gif: 'image/gif',
    hs: 'application/haskell',
    html: 'text/html',
    ico: 'image/x-ico',
    jpeg: 'image/jpeg',
    jpg: 'image/jpeg',
    js:  'application/javascript',
    json:  'application/json',
    log: 'text/log',
    markdown: 'application/markdown',
    m4a: 'audio/mp4',
    md: 'application/markdown',
    mkv: 'video/matroska',
    mp3: 'audio/mpeg',
    mp4: 'video/mp4',
    mpg: 'video/mpg',
    n3: 'text/n3',
    nfo: 'text/nfo',
    nt:  'text/ntriples',
    ntriples:  'text/ntriples',
    owl: 'application/rdf+xml',
    pdf: 'application/pdf',
    pl:  'application/perl',
    png: 'image/png',
    py:  'application/python',
    rb:  'application/ruby',
    ru:  'application/ruby',
    rdf: 'application/rdf+xml',
    rtf: 'text/rtf',
    ssv: 'text/semicolon-separated-values',
    textile: 'application/textile',
    tsv: 'text/tab-separated-values',
    ttl: 'text/turtle',
    txt: 'text/plain',
    u: 'application/uri',
    wav: 'audio/wav',
    wmv: 'video/wmv',
    xlsx: 'application/excel',
  }

  # MIME type -> triplrFn
  MIMEsource={
    'application/atom+xml' => [:triplrFeed],
    'application/markdown' => [:triplrMarkdown],
    'application/org'      => [:triplrOrg],
    'application/rdf+xml'  => [:triplrRDFformats,:rdfxml],
    'application/json'     => [:triplrJSON],
    'application/pdf'      => [:triplrPDF],
    'application/textile'  => [:triplrTextile],
    'application/uri'      => [:triplrUriList],
    'application/word'     => [:triplrWord],
    'audio/mp4'            => [:triplrStdOut,'faad -i',Audio],
    'audio/mpeg'           => [:triplrStdOut,'id3info',Audio,/\((.*?)\)$/],
    'audio'                => [:triplrStdOut,'sndfile-info',Audio],
    'inode/symlink'        => [:triplrSymlink],
    'message/rfc822'       => [:triplrMail],
    'text/ansi'            => [:triplrANSI],
    'text/comma-separated-values'=>[:triplrCSV,/,/],
    'text/html'            => [:triplrRDFformats, :rdfa],
    'text/log'             => [:triplrLog],
    'text/nfo'             => [:triplrHref,'cp437'],
    'text/ntriples'        => [:triplrRDFformats, :ntriples],
    'text/plain'           => [:triplrHref],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values'=>[:triplrCSV,/;/],
    'text/tab-separated-values'=>[:triplrCSV,/\t/],
    'text/turtle'          => [:triplrRDFformats,:turtle],
  }

  # prefer a view even if requested file exists
  MIMEcook={
    'application/atom+xml' => true,
    'application/markdown' => true,
    'application/json+rdf' => true,
    'application/org' => true,
    'application/textile' => true,
    'application/uri' => true,
    'application/word' => true,
    'inode/symlink' => true,
    'message/rfc822'=> true,
    'text/ansi'=>true,
    'text/log'=>true,
    'text/nfo'=>true,
    'text/rtf'=>true}

  %w{c c++ fortran haskell makefile pascal perl php python ruby}.map{|t|
    %w{application/ text/x-}.map{|m|
      MIMEcook[m+t] = true
  }}

  Abbrev={
    "dc" => DC,
    "foaf" => FOAF,
    "rdf" => W3+"1999/02/22-rdf-syntax-ns#",
    "rdfs" => RDFs,
    "sioc" => SIOC,
    "stat" => Stat,
  }
  
  # literal to pathname types
  Literal={}
   [Purl+'dc/elements/1.1/date',
    Date,
    DC+'created',
    Modified,
   ].map{|f|Literal[f]=true}

  def == u
      to_s == u.to_s
  end

  Nginx = ENV['nginx']
  Apache = ENV['apache']

end
