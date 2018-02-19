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

    # link mapped fs-nodes
    def ln n
      FileUtils.ln   node.expand_path, n.node.expand_path
    end
    #TODO relative symlink targets for multiple servers on differing mountpoints
    def ln_s n
      #puts "ln -s #{path} #{n.path}"
      FileUtils.ln_s node.expand_path, n.node.expand_path
    end

    def link n
      send LinkMethod, n unless n.exist?
    rescue Exception => e
      puts e,e.class,e.message
    end

    # read file at location
    def readFile; File.open(localPath).read end

    # write file at location
    def writeFile o; dir.mkdir; File.open(localPath,'w'){|f|f << o}; self end

    # touch mapped node
    def touch
      dir.mkdir
      FileUtils.touch localPath
    end

    # erase mapped node
    def delete
      node.delete
    end

    # contained children minus hidden nodes
    def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map &:R end

    # dirname of mapped path
    def dir; dirname.R if path end
    def dirname; File.dirname path if path end

    # storage-space usage
    def du; `du -s #{sh}| cut -f 1`.chomp.to_i end

    # FIND on path component
    def find p
      (p && !p.empty?) ? `find #{sh} -ipath #{('*'+p+'*').sh} | head -n 2048`.lines.map{|pth|POSIX.path pth.chomp} : []
    end

    # GLOB on path component
    def glob; (Pathname.glob localPath).map &:R end

    # existence check on mapped fs-node
    def exist?; node.exist? end
    def symlink?; node.symlink? end
    alias_method :e, :exist?

    # create container
    def mkdir; FileUtils.mkdir_p localPath unless exist?; self end

    # size of mapped node
    def size; node.size rescue 0 end

    # mtime of mapped node
    def mtime; node.stat.mtime end
    alias_method :m, :mtime

    # storage path -> URI
    def self.path p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R end

    # URI -> storage path
    def localPath; @path ||= (URI.unescape(path[0]=='/' ? '.' + path : path)) end

    # Pathname
    def node; @node ||= (Pathname.new localPath) end

    # shell-escaped path
    def shellPath; localPath.utf8.sh end
    alias_method :sh, :shellPath

    # '/'-separated parts of path component
    def parts; path ? path.split('/') : [] end

    # basename of path component
    def basename; File.basename (path||'') end

    # strip document-format suffixes for content-type agnostic base-URI
    def stripDoc; R[uri.sub /\.(bu|e|html|json|log|md|msg|ttl|txt|u)$/,''] end

    # name suffix
    def ext; (File.extname uri)[1..-1] || '' end

    # TLD of host
    def tld; host && host.split('.')[-1] || '' end

    # SHA2 hash of URI string
    def sha2; to_s.sha2 end

    # WebResource -> file(s)
    def selectNodes
      (if node.directory?
       if q.has_key?('f') && path!='/' # FIND
         found = find q['f']
         q['head'] = true if found.size > 127
         found
       elsif q.has_key?('q') && path!='/' # GREP
         grep q['q']
       else # LS
         if uri[-1] == '/' # inside container
           index = (self+'index.html').glob # static index
           if !index.empty? && qs.empty?
             index
           else
             q['head'] = true # abbreviate to listing only
             @r[:Links][:down] = path + '*' # link to expanded set
             [self, children]
           end
         else # outside container
           @r[:Links][:down] = path + '/' + qs
           self
         end
       end
      else # GLOB
        @r[:glob] = match /[\*\{\[]/
        [self,(@r[:glob] ? self : (self+'.*')).glob]
       end).justArray.flatten.compact.uniq.select &:exist?
    end

    # pattern -> file(s)
    def grep q
      args = POSIX.splitArgs q
      case args.size
      when 0
        return []
      when 2
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -il #{args[1].sh}"
      when 3
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -il #{args[2].sh}"
      when 4
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -ilZ #{args[2].sh} | xargs -0 grep -il #{args[3].sh}"
      else
        pattern = args.join '.*'
        cmd = "grep -ril #{pattern.sh} #{sh}"
      end
      `#{cmd} | head -n 1024`.lines.map{|path| POSIX.path path.chomp}
    end
  end
  module Webize

    # emit RDF of file-metadata
    def triplrFile
      s = path
      yield s, Title, basename

      size.do{|sz|
        yield s, Size, sz}

      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end

    # RDFize container-metadata
    def triplrContainer
      s = path
      s = s + '/' unless s[-1] == '/'
      yield s, Type, R[Container]
      yield s, Title, basename + '/'
      yield s, Size, children.size

      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end

  end

  include POSIX

  module POSIX
    LinkMethod = begin
                   file = '.cache/link'.R
                   link = '.cache/link_'.R
                   file.touch unless file.exist?
                   link.delete if link.exist?
                   file.ln link
                   :ln
                 rescue Exception => e
                   :ln_s
                 end
  end
end
