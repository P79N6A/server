#watch __FILE__

module Th

  def format # memoized selectFormat
    @format ||= selectFormat
  end

  def selectFormat
    { '.html' => 'text/html',
      '.json' => 'application/json',
      '.jsonld' => 'application/ld+json',
      '.nt' => 'text/plain',
      '.n3' => 'text/n3',
      '.rdf' => 'application/rdf+xml',
      '.ttl' => 'text/turtle',
    }[File.extname(self['REQUEST_PATH'])].do{|mime|
      return mime}

    accept.sort.reverse.map{|q,mimes| # Accept in descending q-value
      mimes.map{|mime|
        return mime if RDF::Writer.for(:content_type => mime) || R::Render[mime]}}

    'text/turtle'
  end

end


class R

  def mime # MIME-type of associated fs node
    @mime ||=
      (p = realpath # dereference final location
       unless p     # deref failed?
         nil
       else
         t = ((File.extname p).tail || '').downcase.to_sym
         if p.directory?
           "inode/directory"
         elsif MIME[t]
           MIME[t]
         elsif Rack::Mime::MIME_TYPES[t='.'+t.to_s]
           Rack::Mime::MIME_TYPES[t]
         elsif (File.basename p).index('msg.')==0
           "message/rfc822"
         else
           puts "unknown MIME #{p}"
           `file --mime-type -b #{Shellwords.escape p.to_s}`.chomp
         end
       end )
  end

  MIME={
    aif: 'audio/aif',
    atom: 'application/atom+xml',
    avi: 'video/avi',
    e: 'application/json+rdf',
    coffee: 'text/plain',
    conf: 'text/plain',
    css: 'text/css',
    csv: 'text/csv',
    eps:  'application/postscript',
    flv: 'video/flv',
    for: 'application/fortran',
    gemspec: 'application/ruby',
    gif: 'image/gif',
    go: 'text/x-c',
    haml: 'application/haml',
    hs: 'application/haskell',
    html: 'text/html',
    ico: 'image/x-ico',
    jpeg: 'image/jpeg',
    jpg: 'image/jpeg',
    js:  'application/javascript',
    json:  'application/json',
    jsonld:  'application/ld+json',
    log: 'text/log',
    m4a: 'audio/mp4',
    md: 'text/markdown',
    mkv: 'video/matroska',
    mp3: 'audio/mpeg',
    mp4: 'video/mp4',
    mpg: 'video/mpg',
    n3: 'text/n3',
    nfo: 'text/nfo',
    nt:  'text/ntriples',
    org: 'application/org',
    owl: 'application/rdf+xml',
    pdf: 'application/pdf',
    pl:  'application/perl',
    pm:  'application/perl',
    png: 'image/png',
    ps:  'application/postscript',
    py:  'application/python',
    rb:  'application/ruby',
    ru:  'application/ruby',
    rdf: 'application/rdf+xml',
    rtf: 'text/rtf',
    ssv: 'text/semicolon-separated-values',
    t:  'application/perl',
    tex: 'text/x-tex',
    textile: 'text/textile',
    tsv: 'text/tab-separated-values',
    ttl: 'text/turtle',
    txt: 'text/plain',
    tw: 'text/tw',
    u: 'text/uris',
    url: 'text/plain',
    wav: 'audio/wav',
    wmv: 'video/wmv',
    xlsx: 'application/excel',
    xml: 'application/atom+xml',
  }

  
  MIMEsource={
    'application/atom+xml' => [:triplrFeed],
    'application/org'      => [:triplrOrg],
    'application/json'     => [:triplrJSON],
    'application/pdf'      => [:triplrPDF],
    'application/postscript'=> [:triplrPS],
    'audio/mp4'            => [:triplrStdOut,'faad -i',Audio],
    'audio/mpeg'           => [:triplrStdOut,'id3info',Audio,/\((.*?)\)$/], 
    'audio/x-aiff'         => [:triplrStdOut,'sndfile-info',Audio],
    'audio/x-wav'          => [:triplrStdOut,'sndfile-info',Audio],
    'image'                => [:triplrImage],
    'message/rfc822'       => [:triplrMailMessage],
    'text/csv'             => [:triplrCSV,/,/],
    'text/log'             => [:triplrIRC],
    'text/man'             => [:triplrMan],
    'text/markdown'        => [:triplrMarkdown],
    'text/n3'              => [:triplrN3],
    'text/nfo'             => [:triplrHref,'cp437'],
    'text/plain'           => [:triplrHref],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values'=>[:triplrCSV,/;/],
    'text/tab-separated-values'=>[:triplrCSV,/\t/],
    'text/textile'         => [:triplrTextile],
    'text/turtle'          => [:triplrTurtle],
    'text/tw'              => [:triplrTwUserlist],
    'text/uris'            => [:triplrUriList],
    'text/x-tex'           => [:triplrTeX],
  }

  def triplrMIME &b
    mime.do{|mime|
      (MIMEsource[mime]||
       MIMEsource[mime.split(/\//)[0]]).do{|s|
#        puts "triplr #{uri} #{s}"
        send *s,&b }}
  end

  def triplrN3 &b
    triplrRDF :n3, &b
  end

  def triplrTurtle &b
    triplrRDF :turtle, &b
  end

  def triplrRDF f
    RDF::Reader.open(pathPOSIX, :format => f, :base_uri => stripDoc){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s,[RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}}
  end

end
