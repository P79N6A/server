# coding: utf-8
class WebResource
  module MIME

    # name-prefix -> MIME
    MIMEprefix = {
      'authors' => 'text/plain',
      'changelog' => 'text/plain',
      'contributors' => 'text/plain',
      'copying' => 'text/plain',
      'dockerfile' => 'text/x-docker',
      'gemfile' => 'text/x-ruby',
      'licence' => 'text/plain',
      'license' => 'text/plain',
      'makefile' => 'text/x-makefile',
      'notice' => 'text/plain',
      'procfile' => 'text/x-ruby',
      'rakefile' => 'text/x-ruby',
      'readme' => 'text/plain',
      'thanks' => 'text/plain',
      'todo' => 'text/plain',
      'unlicense' => 'text/plain',
      'msg' => 'message/rfc822',
    }

    # name-suffix -> MIME
    MIMEsuffix = {
      'asc' => 'text/plain',
      'atom' => 'application/atom+xml',
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
      'go' => 'application/go',
      'haml' => 'text/plain',
      'hs' => 'application/haskell',
      'in' => 'text/x-makefile',
      'ini' => 'text/ini',
      'ino' => 'application/ino',
      'lisp' => 'text/x-lisp',
      'list' => 'text/plain',
      'log' => 'text/chatlog',
      'mbox' => 'application/mbox',
      'md' => 'text/markdown',
      'msg' => 'message/rfc822',
      'opml' => 'text/xml+opml',
      'pid' => 'text/plain',
      'rb' => 'text/x-ruby',
      'rst' => 'text/restructured',
      'ru' => 'text/x-ruby',
      'sample' => 'application/config',
      'sh' => 'text/x-shellscript',
      'terminfo' => 'application/config',
      'tmp' => 'application/octet-stream',
      'ttl' => 'text/turtle',
      'u' => 'text/uri-list',
      'webp' => 'image/webp',
      'woff' => 'application/font',
      'yaml' => 'text/plain',
    }

    # MIME -> name-suffix
    MIMEext = MIMEsuffix.invert

    # MIME -> RDF emitter-method
    Triplr = {
      'application/config'   => [:triplrDataFile],
      'application/font'      => [:triplrFile],
      'application/go'   => [:triplrCode],
      'application/haskell'   => [:triplrCode],
      'application/javascript' => [:triplrCode],
      'application/ino'      => [:triplrCode],
      'application/json'      => [:triplrDataFile],
      'application/mbox'      => [:triplrMbox],
      'application/octet-stream' => [:triplrFile],
      'application/org'      => [:triplrOrg],
      'application/pdf'      => [:triplrFile],
      'application/msword'   => [:triplrWordDoc],
      'application/msword+xml' => [:triplrWordXML],
      'application/pkcs7-signature' => [:triplrFile],
      'application/rtf'      => [:triplrRTF],
      'application/ruby'     => [:triplrCode],
      'application/sh'      => [:triplrCode],
      'application/x-sh'     => [:triplrCode],
      'application/xml'     => [:triplrDataFile],
      'application/x-executable' => [:triplrFile],
      'application/x-gzip'   => [:triplrArchive],
      'application/zip'   => [:triplrArchive],
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
      'text/css'             => [:triplrCode],
      'text/csv'             => [:triplrCSV,/,/],
      'text/html'            => [:triplrHTML],
      'text/man'             => [:triplrMan],
      'text/xml+opml'        => [:triplrOPML],
      'text/x-batch'         => [:triplrBat],
      'text/x-c'             => [:triplrCode],
      'text/x-asm'           => [:triplrCode],
      'text/x-lisp'          => [:triplrLisp],
      'text/x-docker'        => [:triplrDocker],
      'text/ini'             => [:triplrIni],
      'text/x-makefile'      => [:triplrMakefile],
      'text/x-java-source'   => [:triplrCode],
      'text/x-ruby'          => [:triplrRuby],
      'text/x-php'           => [:triplrCode],
      'text/x-python'        => [:triplrCode],
      'text/x-script.ruby'   => [:triplrCode],
      'text/x-script.python' => [:triplrCode],
      'text/x-shellscript'   => [:triplrShellScript],
      'text/markdown'        => [:triplrMarkdown],
      'text/nfo'             => [:triplrText,'cp437'],
      'text/plain'           => [:triplrText],
      'text/restructured'    => [:triplrCode],
      'text/rtf'             => [:triplrRTF],
      'text/semicolon-separated-values' => [:triplrCSV,/;/],
      'text/tab-separated-values' => [:triplrCSV,/\t/],
      'text/uri-list'        => [:triplrUriList],
      'text/based-uri-list'        => [:triplrUriList,true],
      'text/x-tex'           => [:triplrTeX],
    }

    MediaMIME = /(audio|font|image|video)/

    # set MIME type
    def setMIME m
      @mime = m
      self
    end

    # get MIME type, prefer memo setting with filename and file-sniffing defaults
    def getMIME
      @mime ||= # memoized
        (name = path || ''
         prefix = ((File.basename name).split('.')[0]||'').downcase
         suffix = ((File.extname name)[1..-1]||'').downcase
         if node.directory?
           'inode/directory'
         elsif MIMEsuffix[suffix] # suffix mapping
           MIMEsuffix[suffix]
         elsif MIMEprefix[prefix] # prefix mapping
           MIMEprefix[prefix]
         elsif Rack::Mime::MIME_TYPES['.'+suffix] # suffix mapping (Rack fallback)
           Rack::Mime::MIME_TYPES['.'+suffix]
         elsif basename == 'body'
           R[dirname+'/MIME'].readFile.split(';')[0]
         else
           puts "WARNING undefined extension for #{localPath}, sniffing content"
           `file --mime-type -b #{Shellwords.escape localPath.to_s}`.chomp
         end)
    end
    alias_method :mime, :getMIME

    # environment -> MIME(s)
    def accept k = 'HTTP_ACCEPT'
      index = {}
      @r[k].do{|v|
        (v.split /,/).map{|e|  # split to (MIME,q) pairs
          format, q = e.split /;/ # split (MIME,q) pair
          i = q && q.split(/=/)[1].to_f || 1.0 # find q-value
          index[i] ||= []
          index[i].push format.strip}} # index on q-value
      index
    end

    # environment -> MIME
    def selectMIME default = 'text/html'
      return 'application/atom+xml' if q.has_key?('feed')

      # preference map
      accept.sort.reverse.map{|q,formats| # index on ordered q-value
        formats.map{|mime|
          return default if mime == '*/*' # wildcard
          return mime if RDF::Writer.for(:content_type => mime) ||          # RDF format
                         %w{application/atom+xml text/html}.member?(mime)}} # non-RDF
      default # HTML
    end
  end

  include MIME

  module HTTP

    # file -> HTTP Response
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

  end

end
