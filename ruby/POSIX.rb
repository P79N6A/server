class Pathname
  def R; R::POSIX.path to_s.utf8 end
end
class WebResource
  module POSIX

    # generally, we prefer hard-links for files which won't be synched to another machine (causing space-waste on remote with naive copy utils),
    # owing to less indirection (notably faster on certain slow-seek media and filesystems) and resilience (not dependent on target-file nonerasure)
    # however Windows and Android (seemingly due to Windows-compat sdcard fs) often fail to support them
    LinkMethod = begin
                   file = '.cache/link'.R
                   link = '.cache/link_'.R
                   file.node.touch unless file.exist?
                   link.node.delete if link.exist?
                   file.ln link
                   :ln
                 rescue Exception => e
                   puts e
                   :ln_s
                 end

    # link mapped nodes
    def ln x,y;   FileUtils.ln   x.node.expand_path, y.node.expand_path end
    # symlink mapped nodes
    def ln_s x,y; FileUtils.ln_s x.node.expand_path, y.node.expand_path end
    # prefer hard but fallback to soft
    def link; send LinkMethod end

    # read file at location of POSIX path-map
    def readFile; File.open(localPath).read end
    # write file at location of POSIX path-map
    def writeFile o; dir.mkdir; File.open(localPath,'w'){|f|f << o}; self end

    # contained children excepting invisible nodes
    def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map &:R end
    # dirname of path component, mapped to WebResource
    def dir; dirname.R end
    # dirname of path component as String
    def dirname; File.dirname path end

    # storage-space usage
    def du; `du -s #{sh}| cut -f 1`.chomp.to_i end

    # FIND on path component
    def find p
      (p && !p.empty?) ? `find #{sh} -ipath #{('*'+p+'*').sh} | head -n 1024`.lines.map{|pth|POSIX.path pth.chomp} : []
    end
    # GLOB on path component
    def glob; (Pathname.glob localPath).map &:R end

    # existence check on mapped fs-node
    def exist?; node.exist? end
    alias_method :e, :exist?

    def mkdir; FileUtils.mkdir_p localPath unless exist?; self end
    # size of mapped node
    def size; node.size rescue 0 end
    # mtime of mapped node
    def mtime; node.stat.mtime end
    alias_method :m, :mtime

    # POSIX path -> URI
    def self.path p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R rescue '/'.R  end

    # URI -> POSIX path
    def localPath; @path ||= (URI.unescape(path[0]=='/' ? '.' + path : path)) end

    # Pathname object
    def node; @node ||= (Pathname.new localPath) end

    # shell-escaped path
    def shellPath; localPath.utf8.sh end
    alias_method :sh, :shellPath

    # '/'-separated parts of path component
    def parts; path ? path.split('/') : [] end

    # basename of path component
    def basename; File.basename (path||'') end

    # fragment || basename || host
    def label; fragment || (path && basename != '/' && (URI.unescape basename)) || host || '' end

    # strip extension of native document formats
    def stripDoc; R[uri.sub /\.(bu|e|html|json|log|md|msg|ttl|txt|u)$/,''] end

    # name-extension of path component
    def ext; (File.extname uri)[1..-1] || '' end

    # TLD of host component
    def tld; host && host.split('.')[-1] || '' end

    # SHA2 hash of URI as string
    def sha2; to_s.sha2 end

    # env -> file(s)
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
           !index.empty? && qs.empty? && index || [self, children]
         else # outside container
           @r[:Links][:down] = path + '/' + qs
           self
         end
       end
      else # GLOB
        @r[:glob] = match /\*/
        [(@r[:glob] ? self : (self+'.*')).glob,
         join('index.ttl').R]
       end).justArray.flatten.compact.select &:exist?
    end

    # pattern -> file(s)
    def grep q
      args = q.shellsplit
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
    # emit RDF of file metadata
    def triplrFile
      s = path
      size.do{|sz|yield s, Size, sz}
      yield s, Title, basename
      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end
    # emit RDF of container metadata
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
end
