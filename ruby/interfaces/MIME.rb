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
      'r' => 'text/x-ruby',
    }

    # name suffix -> MIME
    MIMEsuffix = {
      'asc' => 'text/plain',
      'bat' => 'text/x-batch',
      'cfg' => 'text/ini',
      'chk' => 'text/plain',
      'conf' => 'application/config',
      'desktop' => 'application/config',
      'doc' => 'application/msword',
      'docx' => 'application/msword+xml',
      'dat' => 'application/octet-stream',
      'db' => 'application/octet-stream',
      'e' => 'application/json',
      'eot' => 'application/font',
      'feed' => 'application/atom+xml',
      'go' => 'application/go',
      'haml' => 'text/plain',
      'hs' => 'application/haskell',
      'in' => 'text/x-makefile',
      'ini' => 'text/ini',
      'ino' => 'application/ino',
      'md' => 'text/markdown',
      'msg' => 'message/rfc822',
      'list' => 'text/plain',
      'log' => 'text/chatlog',
      'opml' => 'text/xml+opml',
      'ru' => 'text/x-ruby',
      'rb' => 'text/x-ruby',
      'rst' => 'text/restructured',
      'sample' => 'application/config',
      'sh' => 'text/x-shellscript',
      'terminfo' => 'application/config',
      'tmp' => 'application/octet-stream',
      'ttl' => 'text/turtle',
      'u' => 'text/uri-list',
      'woff' => 'application/font',
      'yaml' => 'text/plain'}

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

    # file(s) -> graph-in-tree
    def load set
      graph = RDF::Graph.new # graph
      g = {}                 # tree
      rdf,nonRDF = set.partition &:isRDF #partition on file type
      # load RDF
      rdf.map{|n|graph.load n.localPath, :base_uri => n}
      graph.each_triple{|s,p,o| # each triple
        s = s.to_s; p = p.to_s # subject, predicate
        o = [RDF::Node, RDF::URI, WebResource].member?(o.class) ? o.R : o.value # object
        g[s] ||= {'uri'=>s} # new resource
        g[s][p] ||= []
        g[s][p].push o unless g[s][p].member? o} # RDF to tree
      # load nonRDF
      nonRDF.map{|n|
        n.transcode.do{|transcode| # transcode to RDF
          ::JSON.parse(transcode.readFile).map{|s,re| # subject
            re.map{|p,o| # predicate, objects
              o.justArray.map{|o| # object
                o = o.R if o.class==Hash
                g[s] ||= {'uri'=>s} # new resource
                g[s][p] ||= []; g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}}} # RDF to tree
      if q.has_key?('du') && path != '/' # DU usage-count
        set.select{|d|d.node.directory?}.-([self]).map{|node|
          g[node.path+'/']||={}
          g[node.path+'/'][Size] = node.du}
      elsif (q.has_key?('f')||q.has_key?('q')||@r[:glob]) && path!='/' # FIND/GREP counts
        set.map{|r|
          bin = r.dirname + '/'
          g[bin] ||= {'uri' => bin, Type => Container}
          g[bin][Size] = 0 if !g[bin][Size] || g[bin][Size].class==Array
          g[bin][Size] += 1}
      end
      g
    end

    # file(s) -> graph
    def loadRDF set
      g = RDF::Graph.new; set.map{|n|g.load n.toRDF.localPath, :base_uri => n.stripDoc}
      g
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
