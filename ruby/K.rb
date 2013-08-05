class E

  FSbase   = `pwd`.chomp
  Prefix   = '/@' # resolver for non-local and non-HTTP URIs
  S        = '<>' # path separator

  # frequently-used URIs
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
  Posix    = W3   + 'ns/posix/'
  Stat     = Posix + 'stat#'
  Label    = RDFs + 'label'
  EXIF     = 'http://www.w3.org/2003/12/exif/ns#'
  Audio    = 'http://www.semanticdesktop.org/ontologies/nid3/#'

  # file-name extension -> MIME type
  MIME={
    aif: 'audio/aif',
    ans: 'text/ansi',
    atom: 'application/atom+xml',
    avi: 'video/avi',
    e: 'application/json+rdf',
    css: 'text/css',
    csv: 'text/comma-separated-values',
    doc: 'application/word',
    flv: 'video/flv',
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
    n3: 'text/rdf+n3',
    nfo: 'text/nfo',
    nt:  'text/ntriples',
    ntriples:  'text/ntriples',
    owl: 'application/rdf+xml',
    pdf: 'application/pdf',
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
    'image'                => [:triplrStdOut,'exiftool',EXIF],
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

  # MIME type -> formatted content
     Render='render/'
  fn Render+'application/ld+json',->d,_=nil{E.renderRDF d, :jsonld}
  fn Render+'application/rdf+xml',->d,_=nil{E.renderRDF d, :rdfxml}
  fn Render+'text/ntriples',->d,_=nil{E.renderRDF d, :ntriples}
  fn Render+'text/turtle',  ->d,_=nil{E.renderRDF d, :turtle}
  fn Render+'text/rdf+n3',  ->d,_=nil{E.renderRDF d, :n3}
  fn Render+'text/n3',      ->d,_=nil{E.renderRDF d, :n3}

  # render a view even if requested file exists
  MIMEcook={
    'application/atom+xml' => true,
    'application/markdown' => true,
    'application/c' => true,
    'application/json+rdf' => true,
    'application/ruby' => true,
    'application/haskell' => true,
    'application/org' => true,
    'application/php' => true,
    'application/python' => true,
    'application/textile' => true,
    'application/word' => true,
    'message/rfc822'=> true,
    'text/ansi'=>true,
    'text/log'=>true,
    'text/nfo'=>true,
    'text/rtf'=>true,
  }

  # short -> full URI
  Abbrev={
    "dc" => DC,
    "foaf" => FOAF,
    "rdf" => W3+"1999/02/22-rdf-syntax-ns#",
    "rdfs" => RDFs,
    "sioc" => SIOC,
    "stat" => Stat,
  }
  
  # expose these literals as a path-name 
  Literal={}
   [Purl+'dc/elements/1.1/date',
    Date,
    DC+'created',
    Modified,
   ].map{|f|Literal[f]=true}

  def mime
    @mime ||= (# dereference symlink
               f = readlink

               # filename extension
               x = f.ext.downcase.to_sym

               # directory?
               if f.d?
                 "inode/directory"
               # local MIME-types table
               elsif MIME[x]
                 MIME[x]
               # Rack MIME-types table
               elsif Rack::Mime::MIME_TYPES[t = '.' + x.to_s]
                 Rack::Mime::MIME_TYPES[t]
               # procmail uses a prefix not an extension
               elsif base.index('msg.')==0
                 "message/rfc822"
               # ask FILE(1)
               elsif e
                 `file --mime-type -b #{sh}`.chomp
               # default
               else
                 "application/octet-stream"
               end)
  end

  def == u
      to_s == u.to_s
  end

  Nginx = ENV['nginx']
  Apache = ENV['apache']
  Version = 'http://web.whats-your.name/www/'

end
