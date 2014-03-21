class FalseClass
  def do; false end
end

class NilClass
  def do; nil end
  def html e=nil; "" end
  def R; "".R end
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

# URI -> function
def fn u,y
  R::F[u] = y
end

def R uri
  R.new uri
end

class R

  def R uri = nil
    uri ? R.new(uri) : self
  end

  def R.[] uri; R.new uri end

  F={}
  Watch={}
  NullView = -> d,e {}

  def self.dev
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def appendURI u; R uri + u.to_s end
  def appendSlashURI u; R uri.t + u.to_s end
  def basename; File.basename path end
  def barename; basename.sub(/\.#{ext}$/,'') rescue basename end
  def cascade; [self].concat parents end
  def children; node.c.map &:R end
  def container; @u ||= R[f ? dirname + '/.' + (File.basename path) : path] end
  def d;        node.to_s end
  def dirname;  node.dirname.do{|d| d.to_s.size <= BaseLen ? '/' : d }.R end
  def docBase;  uri.split(/#/)[0].do{|u|R[u.sub(/\.(e|html|n3|nt|owl|rdf|ttl|txt)$/,"")]} end
  def expand;   uri.expand.R end
  def ext;      File.extname(uri).tail||'' end
  def glob p=""; (Pathname.glob d + p).map &:R end
  def inside;   node.expand_path.to_s.index(FSbase) == 0 end
  def node;     Pathname.new FSbase + path end
  def parent;   R Pathname.new(uri).parent end
  def parents;  parent.do{|p|p.uri.match(/^[.\/]+$/) ? [p] : [p].concat(p.parents)} end
  def path;     uri.match(/^\//) ? uri : ('/'+uri) end
  def pathSegment; uri.match(/^([a-z]+:\/\/[^\/]+)?(\/.*)/).do{|p|p[2]&&p[2].R}||nil end
  def realpath; node.realpath rescue Errno::ENOENT end
  def shorten;  uri.shorten.R end
  def size;     node.size end
  def == u;     to_s == u.to_s end
  def <=> c;    to_s <=> c.to_s end
  def sh;       d.force_encoding('UTF-8').sh end
  
  alias_method :+, :appendURI
  alias_method :a, :appendURI
  alias_method :as, :appendSlashURI
  alias_method :base, :basename
  alias_method :bare, :barename
  alias_method :c, :children
  alias_method :dir, :dirname
  alias_method :maybeURI, :to_s
  alias_method :url, :to_s
  alias_method :uri, :to_s

  def localURL e
    if uri.index('/') == 0
      uri             # already a local path
    elsif e && uri.index('http://'+e['SERVER_NAME']+'/') == 0 
      pathSegment.uri # host match, unchanged local path
    else
      '/' + uri       # URI -> local path
    end
  end

  def objectPath o
    p,v=(if o.class == R
           [o.path, nil]
         else
           literal o
         end)
    [(a p), v]
  end

  def literal o
    str = nil
    ext = nil
    if o.class == String
      str = o;         ext='.txt'
    else
      str = o.to_json; ext='.json'
    end
    ['/'+str.h+ext, str]
  end

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

  def unpath skip = R::BaseLen
    self[skip..-1].do{|p|
      (p.match(/^\/([a-z]+:)\/+(.*)/).do{|m|m[1]+'//'+m[2]}||p).R}
  end

  def R; R.new self end
  def sh; Shellwords.escape self end

end
