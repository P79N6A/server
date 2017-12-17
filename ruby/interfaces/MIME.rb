# coding: utf-8
class R
  module MIME

    # basename-prefix -> MIME
    MIMEprefix = {
      'authors' => 'text/plain',
      'changelog' => 'text/plain',
      'contributors' => 'text/plain',
      'copying' => 'text/plain',
      'install' => 'text/x-shellscript',
      'license' => 'text/plain',
      'readme' => 'text/markdown',
      'todo' => 'text/plain',
      'unlicense' => 'text/plain',
      'msg' => 'message/rfc822'}

    # basename-suffix -> MIME
    MIMEsuffix = {
      'asc' => 'text/plain',
      'chk' => 'text/plain',
      'conf' => 'application/config',
      'desktop' => 'application/config',
      'doc' => 'application/msword',
      'docx' => 'application/msword+xml',
      'dat' => 'application/octet-stream',
      'db' => 'application/octet-stream',
      'e' => 'application/json',
      'eot' => 'application/font',
      'go' => 'application/go',
      'haml' => 'text/plain',
      'hs' => 'application/haskell',
      'ini' => 'text/plain',
      'ino' => 'application/ino',
      'md' => 'text/markdown',
      'msg' => 'message/rfc822',
      'list' => 'text/plain',
      'log' => 'text/chatlog',
      'ru' => 'text/plain',
      'rb' => 'application/ruby',
      'rst' => 'text/restructured',
      'sample' => 'application/config',
      'sh' => 'text/x-shellscript',
      'terminfo' => 'application/config',
      'tmp' => 'application/octet-stream',
      'ttl' => 'text/turtle',
      'u' => 'text/uri-list',
      'woff' => 'application/font',
      'yaml' => 'text/plain'}

    # MIME -> RDF-ize function
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
      'application/makefile'      => [:triplrSourceCode],
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
      'text/x-c'             => [:triplrSourceCode],
      'text/x-ruby'          => [:triplrSourceCode],
      'text/x-php'           => [:triplrSourceCode],
      'text/x-python'        => [:triplrSourceCode],
      'text/x-script.ruby'   => [:triplrSourceCode],
      'text/x-script.python' => [:triplrSourceCode],
      'text/x-shellscript'   => [:triplrFile],
      'text/markdown'        => [:triplrMarkdown],
      'text/nfo'             => [:triplrText,'cp437'],
      'text/plain'           => [:triplrText],
      'text/restructured'    => [:triplrMarkdown],
      'text/rtf'             => [:triplrRTF],
      'text/semicolon-separated-values' => [:triplrCSV,/;/],
      'text/tab-separated-values' => [:triplrCSV,/\t/],
      'text/uri-list'        => [:triplrUriList],
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
           puts "#{pathPOSIX} unmapped MIME, sniffing content (SLOW)"
           `file --mime-type -b #{Shellwords.escape pathPOSIX.to_s}`.chomp
         end)
    end

    def isRDF; %w{atom n3 rdf owl ttl}.member? ext end

    # nonRDF file -> RDF file
    def transcode
      return self if ext == 'e'
      hash = node.stat.ino.to_s.sha2
      doc = R['/.cache/'+hash[0..2]+'/'+hash[3..-1]+'.e']
      unless doc.e && doc.m > m
        tree = {}
        triplr = ::R::Webize::Triplr[mime]
        puts "triplin #{triplr}"
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
  end
end
