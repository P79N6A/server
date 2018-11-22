class Pathname
  def R; R::POSIX.path to_s.utf8 end
end
class WebResource
  module POSIX
    GlobChars = /[\*\{\[]/

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

    def lines; e ? (open localPath).readlines.map(&:chomp) : [] end

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
    def localNodes
      return [] if path == '/' && !localhost? 
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
      else # GLOB
        if match GlobChars
          files = glob
        else # default globs
          files = (self + '.*').glob                # base & ext
          files = (self + '*').glob if files.empty? # prefix
        end
        [self, files]
       end).justArray.flatten.compact.uniq.select &:exist?
    end

    def self.splitArgs args
      args.shellsplit
    rescue
      puts "tokenize failure: #{args}"
      args.split /\W/
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

    # file -> HTTP Response
    def fileResponse
      @r[:Response]['Content-Type'] ||= (%w{text/html text/turtle}.member?(mime) ? (mime + '; charset=utf-8') : mime)
      @r[:Response].update({'ETag' => [m,size].join.sha2, 'Access-Control-Allow-Origin' => '*'})
      @r[:Response].update({'Cache-Control' => 'no-transform'}) if @r[:Response]['Content-Type'].match /^(audio|image|video)/
      if q.has_key?('preview') && ext.match(/(mp4|mkv|png|jpg)/i)
        filePreview
      else
        entity @r
      end
    end

    # files -> HTTP Response
    def files set
      return notfound if !set || set.empty?

      # header
      dateMeta
      format = selectMIME
      @r[:Response].update({'Link' => @r[:links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:links].empty?
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format, 'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha2})

      # body
      entity @r, ->{
        if set.size == 1 && set[0].mime == format
          set[0] # on-file response body
        else
          if format == 'text/html'
            ::Kernel.load HTML::SourceCode if ENV['DEV']
            htmlDocument load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF format
            g = RDF::Graph.new
            set.map{|n|
              g.load n.toRDF.localPath, :base_uri => n.stripDoc }
            g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
          end
        end}
    end
  end
  module POSIX

    # fs-link capability test
    LinkMethod = begin
                   file = 'cache/test/link'.R
                   link = 'cache/test/link_'.R
                   # reset src-state
                   file.touch unless file.exist?
                   # reset dest-state
                   link.delete if link.exist?
                   # try link
                   file.ln link
                   # hard-link succeeded, return
                   :ln
                 rescue Exception => e
                   # symbolic-link fallback
                   :ln_s
                 end
  end
end

class String
  def sh; Shellwords.escape self end
end
