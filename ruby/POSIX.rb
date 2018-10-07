class Pathname
  def R; R::POSIX.path to_s.utf8 end
end
class WebResource
  module POSIX

    def self.splitArgs args
      args.shellsplit
    rescue
      puts "shell tokenization failed: #{args}"
      args.split(/\W/)
    end

    def link n
      send LinkMethod, n unless n.exist?
    rescue Exception => e
      puts e,e.class,e.message
    end
    def ln n
      FileUtils.ln   node.expand_path, n.node.expand_path
    end
    def ln_s n
      FileUtils.ln_s node.expand_path, n.node.expand_path
    end

    def readFile; File.open(localPath).read end

    def writeFile o; dir.mkdir; File.open(localPath,'w'){|f|f << o}; self end

    def touch
      dir.mkdir
      FileUtils.touch localPath
    end

    def size; node.size rescue 0 end

    def mtime; node.stat.mtime end
    alias_method :m, :mtime

    def delete
      node.delete
    end

    def exist?; node.exist? end
    alias_method :e, :exist?

    def symlink?; node.symlink? end

    def children
      node.children.delete_if{|f|
        f.basename.to_s.index('.')==0
      }.map &:R
    rescue Errno::EACCES
      puts "access error for #{path}"
      []
    end

    # dirname as reference
    def dir; dirname.R if path end

    # dirname in string
    def dirname; File.dirname path if path end

    # storage usage
    def du; `du -s #{sh}| cut -f 1`.chomp.to_i end

    # create container
    def mkdir; FileUtils.mkdir_p localPath unless exist?; self end

    # fs-path -> URI
    def self.path p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R end

    # URI -> fs-path
    def localPath; @path ||= (URI.unescape(path[0]=='/' ? '.' + path : path)) end

    # Pathname
    def node; @node ||= (Pathname.new localPath) end
    def directory?; node.directory? end
    def file?; node.file? end

    # shell-escaped path
    def shellPath; localPath.utf8.sh end
    alias_method :sh, :shellPath

    # path nodes
    def parts
      @parts ||= if path
                   if path[0]=='/'
                     path[1..-1]
                   else
                     path
                   end.split '/'
                 else
                   []
                 end
    end

    # basename of path
    def basename; File.basename (path||'') end

    # strip native format suffixes
    def stripDoc; R[uri.sub /\.(bu|e|html|json|log|md|msg|opml|ttl|txt|u)$/,''] end

    # suffix
    def ext; (File.extname uri)[1..-1] || '' end

    # SHA2 hashed URI
    def sha2; to_s.sha2 end

    # WebResource -> file(s) mapping
    def selectNodes
      (if directory?
       if q.has_key?('f') && path!='/' # FIND
         found = find q['f']
         found
       elsif q.has_key?('q') && path!='/' # GREP
         grep q['q']
       else # LS
         if uri[-1] == '/'
           index = (self+'index.html').glob
           if !index.empty? && qs.empty? # static index
             index
           else
             [self, children]
           end
         else # outside container
           @r[:links][:down] = path + '/' + qs
           self
         end
       end
      else # parametric or default glob (base.ext)
        [self, ((match /[\*\{\[]/) ? self : (self + '.*')).glob ]
       end).justArray.flatten.compact.uniq.select &:exist?
    end

  end

  include POSIX

  module Webize
    # file -> RDF
    def triplrFile
      s = path
      yield s, Title, basename
      size.do{|sz| yield s, Size, sz}
      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end

    # directory -> RDF
    def triplrContainer
      s = path
      s = s + '/' unless s[-1] == '/'
      yield s, Type, R[Container]
      yield s, Size, children.size
      yield s, Title, basename
      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end
  end
  module HTTP

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

    def fileResponse
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(mime) ? (mime+'; charset=utf-8') : mime,
                            'ETag' => [m,size].join.sha2,
                            'Access-Control-Allow-Origin' => '*'
                           })
      @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
      if q.has_key?('preview') && ext.match(/(mp4|mkv|png|jpg)/i)
        filePreview
      else
        entity @r
      end
    end

    def filesResponse set=nil
      if !set || set.empty?
        set = selectNodes
        dateMeta
      end
      return notfound if !set || set.empty?
      format = selectMIME
      @r[:Response].update({'Link' => @r[:links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:links].empty?
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format,
                            'ETag' => [[R[HTML::SourceCode], # cache-bust on renderer,
                                        R['.conf/site.css'], # CSS, or doc changes
                                        *set].sort.map{|r|[r,r.m]}, format].join.sha2})
      entity @r, ->{
        if set.size == 1 && set[0].mime == format
          set[0] # no transcode - file as response body
        else # merge and/or transcode
          if format == 'text/html'
            ::Kernel.load HTML::SourceCode if ENV['DEV']
            htmlDocument load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF
            g = RDF::Graph.new
            set.map{|n| g.load n.toRDF.localPath, :base_uri => n.stripDoc }
            g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
          end
        end}
    end
  end
  module POSIX
    # hard-link capability test
    LinkMethod = begin
                   file = '~/.cache/web/link'.R
                   link = '~/.cache/web/link_'.R
                   # reset src-link state
                   file.touch unless file.exist?
                   # reset dest-link state
                   link.delete if link.exist?
                   # try link
                   file.ln link
                   :ln
                 rescue Exception => e
                   :ln_s
                 end
  end
end
