class FalseClass
  def do; false end
end

class NilClass
  def do; nil end
end

class Object
  def id; self end
  def do; yield self end
  def maybeURI; nil end
  def justArray; [self] end
end

def watch f
  R::Watch[f]=File.mtime f
  puts 'dev '+f end

def R uri
  R.new uri
end

class R

  def R uri = nil
    uri ? R.new(uri) : self
  end

  def R.[] uri; R.new uri end

  View = {}
  FileSet = {}
  ResourceSet = {}
  Render = {}
  GET = {}
  POST = {}

  Watch = {}
  def self.dev
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  GREP_DIRS = []
  VHosts = 'domain'

  def appendURI u; R uri + u.to_s end
  def appendSlashURI u; R uri.t + u.to_s end
  def basename; File.basename path end
  def barename; basename.sub(/\.#{ext}$/,'') rescue basename end
  def cascade;  [stripSlash].concat parents end
  def children; node.c.map &:R end
  def descend;  R uri.t end
  def docroot;  stripFrag.stripDoc.stripSlash end
  def dirname;  node.dirname.do{|d| d.to_s.size <= BaseLen ? '/' : d }.R end
  def expand;   uri.expand.R end
  def ext;      File.extname(uri).tail||'' end
  def filePath; node.to_s end
  def glob p=""; (Pathname.glob d + p).map &:R end
  def inside;   node.expand_path.to_s.index(FSbase) == 0 end
  def justPath; R[path] end
  def node;     Pathname.new FSbase + (host.do{|h|'/' + VHosts + '/' + h + (path||'')} || to_s) end
  def parent;   R Pathname.new(uri).parent end
  def parents;  parent.do{|p|p.uri.match(/^[.\/]+$/) ? [p] : [p].concat(p.parents)} end
  def realpath; node.realpath rescue nil end
  def shorten;  uri.shorten.R end
  def size;     node.size end
  def stripDoc; R[uri.sub(/\.(atom|e|html|json(ld)?|n3|nt|rdf|ttl|txt)$/,"")] end
  def stripFrag; R[uri.split(/#/)[0]] end
  def stripSlash; uri[-1] == '/' ? R[uri[0..-2]] : self end
  def == u;     to_s == u.to_s end
  def <=> c;    to_s <=> c.to_s end
  def sh;       d.force_encoding('UTF-8').sh end
  
  alias_method :+, :appendURI
  alias_method :a, :appendURI
  alias_method :as, :appendSlashURI
  alias_method :base, :basename
  alias_method :bare, :barename
  alias_method :c, :children
  alias_method :d, :filePath
  alias_method :dir, :dirname
  alias_method :maybeURI, :to_s
  alias_method :url, :to_s
  alias_method :uri, :to_s

end

class Hash
  def R; R.new uri end
  def uri; self["uri"]||"" end
  alias_method :url, :uri
  alias_method :maybeURI, :uri
end

class String

  def dive; self[0..2]+'/'+self[3..-1] end

  # expand possibly CURIE entryname
  Expand={}
  def expand
   (Expand.has_key? self) ?
    Expand[self] :
   (Expand[self] =
     match(/([^:]+):([^\/].*)/).do{|e|
      ( R::Prefix[e[1]] || e[1]+':' )+e[2]} || 
     gsub('|','/'))
  end

  # shrink to entryname, CURIE if possible
  def shorten
    R::Prefix.map{|p,f|
      return p + ':' + self[f.size..-1]  if (index f) == 0
    }
    gsub('/','|')
  end

  def unpath skip = R::BaseLen # filePath -> URI
    self[skip..-1].do{|p|
      R[p.match(/^\/#{R::VHosts}\/+(.*)/).do{|m|'//'+m[1]} ||
        p]}
  end

  def R; R.new self end
  def sh; Shellwords.escape self end

end
