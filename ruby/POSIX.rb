class R
  def R.fromPOSIX p; p.sub(/^\./,'').gsub(' ','%20').gsub('#','%23').R rescue '/'.R end
  def pathPOSIX; @path ||= (URI.unescape(path[0]=='/' ? '.' + path : path)) end

  def basename; File.basename (path||'') end
  def children; node.children.delete_if{|f|f.basename.to_s.index('.')==0}.map{|c|c.R.setEnv @r} end
  def dir; dirname.R end
  def dirname; File.dirname path end
  def exist?; node.exist? end
  def ext; (File.extname uri)[1..-1] || '' end
  def du; `du -s #{sh}| cut -f 1`.chomp.to_i end
  def find p; (p && !p.empty?) ? `find #{sh} -ipath #{('*'+p+'*').sh} | head -n 1024`.lines.map{|p|R.fromPOSIX p.chomp} : [] end
  def glob; (Pathname.glob pathPOSIX).map{|p|p.R.setEnv @r} end
  def label; fragment || (path && basename != '/' && (URI.unescape basename)) || host || '' end
  def ln x,y;   FileUtils.ln   x.node.expand_path, y.node.expand_path end
  def ln_s x,y; FileUtils.ln_s x.node.expand_path, y.node.expand_path end
  def match p; to_s.match p end
  def mkdir; FileUtils.mkdir_p pathPOSIX unless exist?; self end
  def mtime; node.stat.mtime end
  def node; @node ||= (Pathname.new pathPOSIX) end
  def parts; path ? path.split('/') : [] end
  def shellPath; pathPOSIX.utf8.sh end
  def size; node.size rescue 0 end
  def stripDoc; R[uri.sub /\.(e|html|json|log|md|msg|ttl|txt)$/,''].setEnv(@r) end

  alias_method :e, :exist?
  alias_method :m, :mtime
  alias_method :sh, :shellPath
  alias_method :uri, :to_s

end
