class E

  B        = `pwd`.chomp
  Blen     = B.size
  Prefix   = '/@'
  S        = '<>'

  # frequently-used URIs
  Purl='http://purl.org/'
  DC=Purl+'dc/terms/'
  SIOC ='http://rdfs.org/sioc/ns#'
  SIOCt='http://rdfs.org/sioc/types#'
  To=SIOC+'addressed_to'
  Date    =DC+'date'
  Modified=DC+'modified'
  Creator =SIOC+'has_creator'
  Title   =DC+'title'
  Content=SIOC+'content'
  W3='http://www.w3.org/'
  Type=W3+"1999/02/22-rdf-syntax-ns#type"
  RDFs=W3+'2000/01/rdf-schema#'
  Label=RDFs+'label'
  HTTP=W3+'2011/http#'
  FOAF="http://xmlns.com/foaf/0.1/"

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
    rb:  'application/ruby',
    ru:  'application/ruby',
    rdf: 'application/rdf+xml',
    rtf: 'text/rtf',
    ssv: 'text/semicolon-separated-values',
    textile: 'application/textile',
    tsv: 'text/tab-separated-values',
    ttl: 'text/turtle',
    txt: 'text/plain',
    wav: 'audio/wav',
    wmv: 'video/wmv',
    xlsx: 'application/excel',
  }

  # MIME type -> triplrFn
  MIMEsource={
    'application/atom+xml' => [:triplrFeed],
    'application/markdown' => [:triplrMarkdown],
    'application/org' => [:triplrOrg],
    'application/rdf+xml'=>[:triplrRDFformats,:rdfxml],
    'application/json' => [:triplrJSON],
    'application/pdf'=>[:triplrPDF],
    'application/textile' => [:triplrTextile],
    'application/word'=>[:triplrWord],
    'audio/mp4'=>[:triplrStdOut,'faad -i','audio/'],
    'audio/mpeg'=>[:triplrStdOut,'id3info','audio/mp3/',/\((.*?)\)$/],
    'audio'=>[:triplrStdOut,'sndfile-info','audio/'],
    'image'=>[:triplrStdOut,'exiftool','exif/'],
    'message/rfc822'=>[:triplrMail],
    'text/ansi'=>[:triplrANSI],
    'text/comma-separated-values'=>[:triplrCSV,/,/],
    'text/html'=>[:triplrRDFformats, :rdfa],
    'text/log'=>[:triplrLog],
    'text/nfo'=>[:triplrHref,'cp437'],
    'text/ntriples'=>[:triplrRDFformats, :ntriples],
    'text/plain'=>[:triplrHref],
    'text/rtf'=>[:triplrRTF],
    'text/semicolon-separated-values'=>[:triplrCSV,/;/],
    'text/tab-separated-values'=>[:triplrCSV,/\t/],
    'text/turtle'=>[:triplrRDFformats,:turtle],
  }

  # MIME type -> formatted content
     Render='render/'
  fn Render+'application/ld+json',->d,_=nil{E.renderRDF d, :jsonld}
  fn Render+'application/rdf+xml',->d,_=nil{E.renderRDF d, :rdfxml}
  fn Render+'text/ntriples',->d,_=nil{E.renderRDF d, :ntriples}
  fn Render+'text/rdf+n3',  ->d,_=nil{E.renderRDF d, :n3}
  fn Render+'text/turtle',  ->d,_=nil{E.renderRDF d, :turtle}

  # render a view even if requested file exists
  MIMEcook={
    'application/atom+xml' => true,
    'application/markdown' => true,
    'application/c' => true,
    'application/ruby' => true,
    'application/haskell' => true,
    'application/org' => true,
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
    "atom" => Atom,
    "dc" => DC,
    "foaf" => FOAF,
    "rdf" => W3+"1999/02/22-rdf-syntax-ns#",
    "rdfs" => RDFs,
    "rss" => RSS,
    "sioc" => SIOC,
    "t" => 'http://www.daml.org/2003/01/periodictable/PeriodicTable#',
  }
  
  # expose these literals as a path-name 
  Literal={}
   [Purl+'dc/elements/1.1/date',
    Date,
    DC+'created',
    Modified,
   ].map{|f|Literal[f]=true}

  def mime
    @mime ||= (f = readlink
               if f.d?
                 "inode/directory"
               elsif MIME[x = f.ext.downcase.to_sym]
                 MIME[x]
               elsif base.index('msg.')==0
                 "message/rfc822"
               else
                 e && `file --mime-type -L -b #{sh}`.chomp
               end)
  end

  def == u
      to_s == u.to_s
  end

end
