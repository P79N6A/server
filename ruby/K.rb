class E

  B        = `pwd`.chomp
  Blen     = B.size
  Prefix   = '/@'
  S        = '<>'

  #extension -> MIMEtype
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
    jsonp:  'application/jsonp',
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
#    org: 'application/org',
    owl: 'application/rdf+xml',
    pdf: 'application/pdf',
    png: 'image/png',
    rb:  'application/ruby',
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

  # MIMEtype -> tripleSource
  MIMEsource={
    'application/atom+xml' => [:feed],
    'application/excel' => [:excel],
    'application/markdown' => [:markdown],
    'application/org' => [:org],
    'application/rdf+xml'=>[:rdf,:rdfxml],
    'application/json' => [:json],
    'application/jsonp' => [:jsonp],
    'application/pdf'=>[:pdf],
    'application/textile' => [:textile],
    'application/word'=>[:word],
    'audio/mp4'=>[:shellData,'faad -i','audio/'],
    'audio/mpeg'=>[:shellData,'id3info','audio/mp3/',/\((.*?)\)$/],
    'audio'=>[:shellData,'sndfile-info','audio/'],
    'image'=>[:shellData,'exiftool','exif/'],
    'message/rfc822'=>[:mail],
    'text/ansi'=>[:ansi],
    'text/comma-separated-values'=>[:csv,/,/],
    'text/log'=>[:log],
    'text/nfo'=>[:hyper,'cp437'],
    'text/ntriples'=>[:rdf, :ntriples],
    'text/plain'=>[:hyper],
    'text/rtf'=>[:rtf],
    'text/semicolon-separated-values'=>[:csv,/;/],
    'text/tab-separated-values'=>[:csv,/\t/],
    'text/turtle'=>[:rdf,:turtle],
  }

  MIMEcook={
    'application/atom+xml' => true,
    'application/markdown' => true,
    'application/c' => true,
    'application/ruby' => true,
    'application/jsonp' => true,
    'application/haskell' => true,
    'application/org' => true,
    'application/textile' => true,
    'application/word' => true,
    'message/rfc822'=> true,
    'text/ansi'=>true,
    'text/log'=>true,
    'text/nfo'=>true,
#    'text/plain'=>true, #
    'text/rtf'=>true,
  }

# URI
  Render='render/'
  Purl='http://purl.org/'
  DC=Purl+'dc/terms/'
  SIOC ='http://rdfs.org/sioc/ns#'
  SIOCt='http://rdfs.org/sioc/types#'
  To=SIOC+'addressed_to'
  Date    =DC+'date'
  Modified=DC+'modified'
  Creator =SIOC+'has_creator'
  Title   =DC+'title'
  RSS=Purl+'rss/1.0/'
  RSSm=RSS+'modules/'
  Content=SIOC+'content'
  W3='http://www.w3.org/'
  Type=W3+"1999/02/22-rdf-syntax-ns#type"
  RDFs=W3+'2000/01/rdf-schema#'
  Label=RDFs+'label'
  XSD =W3+'2001/XMLSchema#'
  Atom=W3+'2005/Atom'
  HTTP=W3+'2011/http#'
  IANA='http://www.iana.org/assignments/'
  Mime=IANA+'media-types/'
  Charset=IANA+'charsets/'
  FOAF="http://xmlns.com/foaf/0.1/"
  
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
  
  # literal->URI hints
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

  # util, prefix -> tripleSource
  def shellData e,f='',g=nil,a=sh;g||=/^\s*(.*?)\s*$/
    `#{e} #{a}|grep :`.each_line{|i|i=i.split /:/
    yield uri,
     (f+(i[0].match(g)||[nil,i[0]])[1].gsub(/\s/,'_')),
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : v}
    };nil
  rescue
    nil
  end

end
