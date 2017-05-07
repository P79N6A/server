class R

  def mime
    @mime ||=
      (p = node.realpath # dereference link(s)
       unless p
         nil
       else
         t = ((File.extname p).tail || '').downcase
         if p.directory?
           "inode/directory"
         elsif (File.basename p).index('msg.')==0
           "message/rfc822"
         elsif MIME[t]
           MIME[t]
         elsif Rack::Mime::MIME_TYPES['.'+t]
           Rack::Mime::MIME_TYPES['.'+t]
         else
           puts "unknown MIME #{p}"
           `file --mime-type -b #{Shellwords.escape p.to_s}`.chomp
         end
       end )
  end

  MIME={
    'aif' => 'audio/aif',
    'asc' => 'text/plain',
    'atom' => 'application/atom+xml',
    'avi' => 'video/avi',
    'bz2' => 'application/bzip2',
    'e' => 'application/json+rdf',
    'eml' => 'message/rfc822',
    'coffee' => 'text/plain',
    'conf' => 'text/plain',
    'css' => 'text/css',
    'csv' => 'text/csv',
    'eps' => 'application/postscript',
    'flv' => 'video/flv',
    'for' => 'application/fortran',
    'gemspec' => 'application/ruby',
    'gif' => 'image/gif',
    'go' => 'text/x-c',
    'gz' => 'application/gzip',
    'haml' => 'application/haml',
    'hs' => 'application/haskell',
    'html' => 'text/html',
    'ht' => 'text/html-fragment',
    'ico' => 'image/x-ico',
    'ini' => 'application/ini',
    'jpeg' => 'image/jpeg',
    'jpg' => 'image/jpeg',
    'jpg-large' => 'image/jpeg',
    'js' => 'application/javascript',
    'json' => 'application/json',
    'jsonld' => 'application/ld+json',
    'log' => 'text/log',
    'm4a' => 'audio/mp4',
    'markdown' => 'text/markdown',
    'md' => 'text/markdown',
    'mkv' => 'video/matroska',
    'mp3' => 'audio/mpeg',
    'mp4' => 'video/mp4',
    'mpg' => 'video/mpg',
    'n3' => 'text/n3',
    'nfo' => 'text/nfo',
    'nt' => 'text/ntriples',
    'org' => 'application/org',
    'owl' => 'application/rdf+xml',
    'pdf' => 'application/pdf',
    'php' => 'application/php',
    'pl' => 'application/perl',
    'pm' => 'application/perl',
    'png' => 'image/png',
    'ps' => 'application/postscript',
    'py' => 'application/python',
    'rb' => 'application/ruby',
    'rev' => 'text/uri-list+index',
    'ru' => 'application/ruby',
    'rdf' => 'application/rdf+xml',
    'rss' => 'application/atom+xml',
    'rtf' => 'text/rtf',
    'ssv' => 'text/semicolon-separated-values',
    't' => 'application/perl',
    'tex' => 'text/x-tex',
    'textile' => 'text/textile',
    'tsv' => 'text/tab-separated-values',
    'ttf' => 'font/truetype',
    'ttl' => 'text/turtle',
    'txt' => 'text/plain',
    'u' => 'text/uri-list',
    'url' => 'text/plain',
    'wav' => 'audio/wav',
    'webp' => 'image/webp',
    'wmv' => 'video/wmv',
    'xlsx' => 'application/excel',
    'xml' => 'application/atom+xml',
    'zip' => 'application/zip',
  }
  
  MIMEsource={
    'application/atom+xml' => [:triplrFeed],
    'application/org'      => [:triplrOrg],
    'application/bzip2'    => [:triplrArchive],
    'application/gzip'     => [:triplrArchive],
    'application/zip'     => [:triplrArchive],
    'audio/mpeg'           => [:triplrAudio],
    'image'                => [:triplrImage],
    'inode/directory'      => [:triplrContainer],
    'message/rfc822'       => [:triplrMailIndexer],
    'text/csv'             => [:triplrCSV,/,/],
    'text/html-fragment'   => [:triplrHTMLfragment],
    'text/log'             => [:triplrIRC],
    'text/man'             => [:triplrMan],
    'text/markdown'        => [:triplrMarkdown],
    'text/n3'              => [:triplrRDF,:n3],
    'text/nfo'             => [:triplrHref,'cp437'],
    'text/plain'           => [:triplrHref],
    'text/rtf'             => [:triplrRTF],
    'text/semicolon-separated-values'=>[:triplrCSV,/;/],
    'text/tab-separated-values'=>[:triplrCSV,/\t/],
    'text/textile'         => [:triplrTextile],
    'text/turtle'          => [:triplrRDF,:turtle],
    'text/tw'              => [:triplrTwUsers],
    'text/uri-list'        => [:triplrUriList],
    'text/x-tex'           => [:triplrTeX],
  }

  def triplrMIME &b
    mime.do{|mime|
      (MIMEsource[mime]||                # exact match
       MIMEsource[mime.split(/\//)[0]]|| # category
       :triplrFile).do{|s|               # nothing found, basic file metadata
        send *s,&b }}
  end

  def triplrRDF f
    RDF::Reader.open(pathPOSIX, :format => f, :base_uri => stripDoc){|r|
      r.each_triple{|s,p,o|
        yield s.to_s, p.to_s,[RDF::Node, RDF::URI].member?(o.class) ? R(o) : o.value}}
  end

  def triplrAudio &f
    yield uri, Type, R[Sound]
  end

  Abstract[Sound] = -> graph, g, e {graph['#audio'] = {Type => R[Sound+'Player']}} # add player

  View[Sound+'Player'] = -> g,e {
    [H.js('/js/audio'),{_: :audio, id: :audio, controls: true}]}

  GET['thumbnail'] = -> e {
    thumb = nil
    path = e.path.sub /^.thumbnail/, ''
    i = R['//' + e.host + path]
    i = R[path] unless i.file? && i.size > 0
    if i.file? && i.size > 0
      if i.ext.match /SVG/i
        thumb = i
      else
        thumb = i.dir.child '.' + i.basename + '.png'
        if !thumb.e
          if i.mime.match(/^video/)
            `ffmpegthumbnailer -s 360 -i #{i.sh} -o #{thumb.sh}`
          else
            `gm convert #{i.ext.match(/^jpg/) ? 'jpg:' : ''}#{i.sh} -thumbnail "360x360" #{thumb.sh}`
          end
        end
      end
      thumb && thumb.e && thumb.setEnv(e.env).fileGET || e.notfound
    else
      e.notfound
    end}

  def triplrImage &f
    yield uri, Type, R[Image]
  end

end
