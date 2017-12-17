class R
  module POSIX

    def self.path p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R rescue '/'.R  end
    def basename; File.basename (path||'') end
    def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map &:R end
    def dir; dirname.R end
    def dirname; File.dirname path end
    def exist?; node.exist? end
    def ext; (File.extname uri)[1..-1] || '' end
    def du; `du -s #{sh}| cut -f 1`.chomp.to_i end
    def find p; (p && !p.empty?) ? `find #{sh} -ipath #{('*'+p+'*').sh} | head -n 1024`.lines.map{|pth|POSIX.path pth.chomp} : [] end
    def glob; (Pathname.glob pathPOSIX).map &:R end
    def label; fragment || (path && basename != '/' && (URI.unescape basename)) || host || '' end
    def ln x,y;   FileUtils.ln   x.node.expand_path, y.node.expand_path end
    def ln_s x,y; FileUtils.ln_s x.node.expand_path, y.node.expand_path end
    def match p; to_s.match p end
    def mkdir; FileUtils.mkdir_p pathPOSIX unless exist?; self end
    def mtime; node.stat.mtime end
    def node; @node ||= (Pathname.new pathPOSIX) end
    def parts; path ? path.split('/') : [] end
    def pathPOSIX; @path ||= (URI.unescape(path[0]=='/' ? '.' + path : path)) end
    def readFile; File.open(pathPOSIX).read end
    def shellPath; pathPOSIX.utf8.sh end
    def size; node.size rescue 0 end
    def stripDoc; R[uri.sub /\.(e|html|json|log|md|msg|ttl|txt)$/,''] end
    def tld; host && host.split('.')[-1] || '' end
    def writeFile o; dir.mkdir; File.open(pathPOSIX,'w'){|f|f << o}; self end
    alias_method :e, :exist?
    alias_method :m, :mtime
    alias_method :sh, :shellPath

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
end
