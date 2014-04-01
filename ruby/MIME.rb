#watch __FILE__
class R

  # no link-follow
  def mime
    @mime ||=
      (t = ext.downcase.to_sym

       if node.symlink?
         "inode/symlink"
       elsif node.directory?
         "inode/directory"
       elsif base.index('msg.')==0 # how to make procmail append a non-gibberish extension?
         "message/rfc822"
       elsif MIME[t]
         MIME[t]
       elsif Rack::Mime::MIME_TYPES[t='.'+t.to_s]
         Rack::Mime::MIME_TYPES[t]
       elsif e
         `file --mime-type -b #{sh}`.chomp
       else
         "application/octet-stream"
       end)
  end

  # recursively-dereferenced links
  def mimeP
    @mime ||=
      (p = realpath
       unless p
         nil
       else
         t = ((File.extname p).tail || '').downcase.to_sym
         if p.directory?
           "inode/directory"
         elsif (File.basename p).index('msg.')==0
           "message/rfc822"
         elsif MIME[t]
           MIME[t]
         elsif Rack::Mime::MIME_TYPES[t='.'+t.to_s]
           Rack::Mime::MIME_TYPES[t]
         else
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
    csv: 'text/comma-separated-values',
    eps:  'application/postscript',
    flv: 'video/flv',
    for: 'application/fortran',
    gemspec: 'application/ruby',
    gif: 'image/gif',
    hs: 'application/haskell',
    ht: 'text/html-part',
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
    org: 'application/org',
    owl: 'application/rdf+xml',
    pdf: 'application/pdf',
    pl:  'application/perl',
    png: 'image/png',
    ps:  'application/postscript',
    py:  'application/python',
    rb:  'application/ruby',
    ru:  'application/ruby',
    rdf: 'application/rdf+xml',
    rtf: 'text/rtf',
    ssv: 'text/semicolon-separated-values',
    tex: 'text/x-tex',
    tsv: 'text/tab-separated-values',
    ttl: 'text/turtle',
    txt: 'text/plain',
    tw: 'text/tw',
    u: 'application/uri',
    url: 'text/plain',
    wav: 'audio/wav',
    wmv: 'video/wmv',
    xlsx: 'application/excel',
  }

  
  MIMEsource={
    'application/atom+xml' => [:triplrFeed],
    'application/markdown' => [:triplrMarkdown],
    'application/org'      => [:triplrOrg],
    'application/rdf+xml'  => [:triplrRDF,:rdfxml],
    'application/json'     => [:triplrJSON],
    'application/pdf'      => [:triplrPDF],
    'application/postscript'=> [:triplrPS],
    'application/uri'      => [:triplrUriList],
    'audio/mp4'            => [:triplrStdOut,'faad -i',Audio],
    'audio/mpeg'           => [:triplrStdOut,'id3info',Audio,/\((.*?)\)$/],
    'audio'                => [:triplrStdOut,'sndfile-info',Audio],
    'image'                => [:triplrImage],
    'inode/symlink'        => [:triplrSymlink],
    'message/rfc822'       => [:triplrMailMessage],
    'text/comma-separated-values'=>[:triplrCSV,/,/],
    'text/html-part'       => [:triplrHTMLpiece],
    'text/log'             => [:triplrIRC],
    'text/man'             => [:triplrMan],
    'text/n3'              => [:triplrRDF, :n3],
    'text/nfo'             => [:triplrHref,'cp437'],
    'text/ntriples'        => [:triplrRDF, :ntriples],
    'text/plain'           => [:triplrHref],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values'=>[:triplrCSV,/;/],
    'text/tab-separated-values'=>[:triplrCSV,/\t/],
    'text/turtle'          => [:triplrRDF,:turtle],
    'text/tw'              => [:triplrTwUser],
    'text/x-tex'           => [:triplrTeX],
  }

  # prefer a view even if requested file exists
  MIMEcook={
    'application/json+rdf' => true,
    'application/markdown' => true,
    'application/org' => true,
    'application/postscript' => true,
    'application/uri' => true,
    'inode/symlink' => true,
    'message/rfc822'=> true,
    'text/html-part'=>true,
    'text/log'=>true,
    'text/man'=>true,
    'text/nfo'=>true,
    'text/rtf'=>true,
    'text/x-tex'=>true,
  }

  %w{c c++ fortran haskell makefile pascal perl php python ruby}.map{|t|
    %w{application/ text/x-}.map{|m|
      MIMEcook[m+t] = true
  }}

  def triplrMIME &b
    mimeP.do{|mime|
      yield uri, R::Type, (R MIMEtype+mimeP)
      (MIMEsource[mimeP]||
       MIMEsource[mimeP.split(/\//)[0]]).do{|s|
        send *s,&b }}
  end

end
