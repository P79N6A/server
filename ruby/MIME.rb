# coding: utf-8
class WebResource
  module MIME
    include URIs

    # name prefix -> MIME
    MIMEprefix = {
      'authors' => 'text/plain',
      'changelog' => 'text/plain',
      'contributors' => 'text/plain',
      'copying' => 'text/plain',
      'dockerfile' => 'text/x-docker',
      'gemfile' => 'text/x-ruby',
      'license' => 'text/plain',
      'makefile' => 'text/x-makefile',
      'todo' => 'text/plain',
      'unlicense' => 'text/plain',
      'msg' => 'message/rfc822',
    }

    # name suffix -> MIME
    MIMEsuffix = {
      'asc' => 'text/plain',
      'bat' => 'text/x-batch',
      'bu' => 'text/based-uri-list',
      'cfg' => 'text/ini',
      'chk' => 'text/plain',
      'conf' => 'application/config',
      'dat' => 'application/octet-stream',
      'db' => 'application/octet-stream',
      'desktop' => 'application/config',
      'doc' => 'application/msword',
      'docx' => 'application/msword+xml',
      'e' => 'application/json',
      'eot' => 'application/font',
      'feed' => 'application/atom+xml',
      'go' => 'application/go',
      'haml' => 'text/plain',
      'hs' => 'application/haskell',
      'in' => 'text/x-makefile',
      'ini' => 'text/ini',
      'ino' => 'application/ino',
      'list' => 'text/plain',
      'log' => 'text/chatlog',
      'md' => 'text/markdown',
      'msg' => 'message/rfc822',
      'opml' => 'text/xml+opml',
      'rb' => 'text/x-ruby',
      'rst' => 'text/restructured',
      'ru' => 'text/x-ruby',
      'sample' => 'application/config',
      'sh' => 'text/x-shellscript',
      'terminfo' => 'application/config',
      'tmp' => 'application/octet-stream',
      'ttl' => 'text/turtle',
      'u' => 'text/uri-list',
      'woff' => 'application/font',
      'yaml' => 'text/plain',
    }

    # MIME -> RDF-yielding function
    Triplr = {
      'application/config'   => [:triplrDataFile],
      'application/font'      => [:triplrFile],
      'application/go'   => [:triplrSourceCode],
      'application/haskell'   => [:triplrSourceCode],
      'application/javascript' => [:triplrSourceCode],
      'application/ino'      => [:triplrSourceCode],
      'application/json'      => [:triplrDataFile],
      'application/octet-stream' => [:triplrFile],
      'application/org'      => [:triplrOrg],
      'application/pdf'      => [:triplrFile],
      'application/msword'   => [:triplrWordDoc],
      'application/msword+xml' => [:triplrWordXML],
      'application/pkcs7-signature' => [:triplrFile],
      'application/rtf'      => [:triplrRTF],
      'application/ruby'     => [:triplrSourceCode],
      'application/sh'      => [:triplrSourceCode],
      'application/x-sh'     => [:triplrSourceCode],
      'application/xml'     => [:triplrDataFile],
      'application/x-executable' => [:triplrFile],
      'application/x-gzip'   => [:triplrArchive],
      'application/vnd.oasis.opendocument.text' => [:triplrOpenDocument],
      'audio/mpeg'           => [:triplrAudio],
      'audio/x-wav'          => [:triplrAudio],
      'audio/3gpp'           => [:triplrAudio],
      'image/bmp'            => [:triplrImage],
      'image/gif'            => [:triplrImage],
      'image/png'            => [:triplrImage],
      'image/svg+xml'        => [:triplrImage],
      'image/tiff'           => [:triplrImage],
      'image/jpeg'           => [:triplrImage],
      'inode/directory'      => [:triplrContainer],
      'message/rfc822'       => [:triplrMail],
      'text/cache-manifest'  => [:triplrText],
      'text/calendar'        => [:triplrCalendar],
      'text/chatlog'         => [:triplrChatLog],
      'text/css'             => [:triplrSourceCode],
      'text/csv'             => [:triplrCSV,/,/],
      'text/html'            => [:triplrHTML],
      'text/man'             => [:triplrMan],
      'text/xml+opml'        => [:triplrOPML],
      'text/x-batch'         => [:triplrBat],
      'text/x-c'             => [:triplrSourceCode],
      'text/x-docker'        => [:triplrDocker],
      'text/ini'             => [:triplrIni],
      'text/x-makefile'      => [:triplrMakefile],
      'text/x-java-source'   => [:triplrSourceCode],
      'text/x-ruby'          => [:triplrRuby],
      'text/x-php'           => [:triplrSourceCode],
      'text/x-python'        => [:triplrSourceCode],
      'text/x-script.ruby'   => [:triplrSourceCode],
      'text/x-script.python' => [:triplrSourceCode],
      'text/x-shellscript'   => [:triplrShellScript],
      'text/markdown'        => [:triplrMarkdown],
      'text/nfo'             => [:triplrText,'cp437'],
      'text/plain'           => [:triplrText],
      'text/restructured'    => [:triplrSourceCode],
      'text/rtf'             => [:triplrRTF],
      'text/semicolon-separated-values' => [:triplrCSV,/;/],
      'text/tab-separated-values' => [:triplrCSV,/\t/],
      'text/uri-list'        => [:triplrUriList],
      'text/based-uri-list'        => [:triplrUriList,true],
      'text/x-tex'           => [:triplrTeX],
    }

    # file -> MIME
    def mime
      @mime ||= # memoize
        (name = path || ''
         prefix = ((File.basename name).split('.')[0]||'').downcase
         suffix = ((File.extname name)[1..-1]||'').downcase
         if node.directory? # container
           'inode/directory'
         elsif MIMEprefix[prefix] # prefix mapping
           MIMEprefix[prefix]
         elsif MIMEsuffix[suffix] # suffix mapping
           MIMEsuffix[suffix]
         elsif Rack::Mime::MIME_TYPES['.'+suffix] # suffix mapping (Rack fallback)
           Rack::Mime::MIME_TYPES['.'+suffix]
         else
           puts "#{localPath} unmapped MIME, sniffing content (SLOW)"
           `file --mime-type -b #{Shellwords.escape localPath.to_s}`.chomp
         end)
    end

    # file -> boolean
    def isRDF; %w{feed n3 ttl}.member? ext end

    # file -> RDF file
    def toRDF; isRDF ? self : transcode end
    def transcode
      return self if ext == 'e'
      hash = node.stat.ino.to_s.sha2
      doc = R['/.cache/'+hash[0..2]+'/'+hash[3..-1]+'.e']
      unless doc.e && doc.m > m
        tree = {}
        triplr = Triplr[mime]
        unless triplr
          puts "WARNING missing #{mime} triplr for #{uri}"
          triplr = :triplrFile
        end
        send(*triplr){|s,p,o|
          tree[s] ||= {'uri' => s}
          tree[s][p] ||= []
          tree[s][p].push o}
        doc.writeFile tree.to_json
      end
      doc
    rescue Exception => e
      puts uri, e.class, e.message
    end

    # file -> preview file
    def filePreview
      p = join('.' + basename + '.jpg').R
      if !p.e
        if mime.match(/^video/)
          `ffmpegthumbnailer -s 256 -i #{sh} -o #{p.sh}`
        else
          `gm convert #{sh} -thumbnail "256x256" #{p.sh}`
        end
      end
      p.e && p.entity(@r) || notfound
    end

    # env -> MIME
    def selectMIME
      return 'application/atom+xml' if q.has_key?('feed')
      index = {}
      @r['HTTP_ACCEPT'].do{|k|
        (k.split /,/).map{|e| # (MIME,q) pairs
          format, q = e.split /;/      # pair
          i = q && q.split(/=/)[1].to_f || 1.0 # q-value with default
          index[i] ||= []
          index[i].push format.strip}} # indexed q-vals
       index.sort.reverse.map{|q,formats| # order index
        formats.map{|mime| # formats tied at q-val. return first serializable
          return mime if RDF::Writer.for(:content_type => mime) || %w{application/atom+xml text/html}.member?(mime)}} # serializable
      'text/html' # default
    end

  end
  module Webize
    def triplrImage &f
      yield uri, Type, R[Image]
      w,h = Dimensions.dimensions localPath
      yield uri, Stat+'width', w
      yield uri, Stat+'height', h
      triplrFile &f
    end
  end
end
