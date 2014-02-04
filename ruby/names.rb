class E

  def appendURI u; E uri + u.to_s end
  def appendSlashURI u; E uri.t + u.to_s end
  def basename; File.basename path end
  def barename; basename.sub(/\.#{ext}$/,'') end
  def cascade; [self].concat parents end
  def children; node.c.map &:E end
  def container; @u ||= E[f ? dirname + '/.' + (File.basename path) : path] end
  def d;        node.to_s end
  def delete;   node.deleteNode if e; self end
  def dirname;  node.dirname.do{|d| d.to_s.size <= BaseLen ? '/' : d }.E end
  def docBase;  uri.split(/#/)[0].E.do{|d| d.dirname.as d.bare } end
  def d?;       node.directory? end
  def env r=nil;r ? (@r = r; self) : @r end
  def exist?;   node.exist? end
  def expand;   uri.expand.E end
  def ext;      File.extname(uri).tail||'' end
  def file?;    node.file? end
  def frag;     uri.frag end
  def get;      open(uri).read end
  def glob p=""; (Pathname.glob d + p).map &:E end
  def hostURL e; host='http://'+e['SERVER_NAME']; (uri.index('/') == 0 ? host : '') + uri end
  def inside;   node.expand_path.to_s.index(FSbase) == 0 end
  def label;    uri.label end
  def mk;       e || FileUtils.mkdir_p(d); self end
  def mtime;    node.stat.mtime if e end
  def node;     Pathname.new FSbase + path end
  def parent;   E Pathname.new(uri).parent end
  def parents;  parent.do{|p|p.uri.match(/^[.\/]+$/) ? [p] : [p].concat(p.parents)} end
  def path;     uri.match(/^\//) ? uri : ('/'+uri) end
  def pathSegment; uri.match(/^([a-z]+:\/\/[^\/]+)?(\/.*)/).do{|p|p[2]&&p[2].E}||nil end
  def predicatePath p,s=true; container.as s ? p.E.shorten : p end
  def predicates; container.c.map{|c|c.base.expand.E} end
  def prependURI u; E u.to_s + uri end
  def read;     f ? readFile : get end
  def readFile; File.open(d).read end
  def realpath; node.realpath rescue Errno::ENOENT end
  def shorten;  uri.shorten.E end
  def siblings; parent.c end
  def size;     node.size end
  def == u;     to_s == u.to_s end
  def <=> c;    to_s <=> c.to_s end
  def sh;       d.force_encoding('UTF-8').sh end
  def to_s;     uri end
  def to_h;    {'uri' => uri} end
  def touch;    FileUtils.touch node; self end
  def writeFile c; File.open(d,'w'){|f|f << c} end

  alias_method :+, :appendURI
  alias_method :a, :appendURI
  alias_method :as, :appendSlashURI
  alias_method :base, :basename
  alias_method :bare, :barename
  alias_method :c, :children
  alias_method :dir, :dirname
  alias_method :e, :exist?
  alias_method :f, :file?
  alias_method :m, :mtime
  alias_method :maybeURI, :uri
  alias_method :url, :uri

  def localURL e
    if uri.index('/') == 0
      uri             # already a local path
    elsif e && uri.index('http://'+e['SERVER_NAME']+'/') == 0 
      pathSegment.uri # host match, unchanged local path
    else
      '/' + uri       # URI -> local path
    end
  end

end

class Hash
  def E; E.new uri end
  def uri; self["uri"]||"" end
  def label; uri.label end
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
      ( E::Prefix[e[1]] || e[1]+':' )+e[2]} || 
     gsub('|','/'))
  end

  # shrink to entryname, CURIE if possible
  def shorten
    E::Prefix.map{|p,f|
      return p + ':' + self[f.size..-1]  if (index f) == 0
    }
    gsub('/','|')
  end

  def unpath skip=E::BaseLen
    self[skip..-1].do{|p|
      (p.match(/^\/([a-z]+:)\/+(.*)/).do{|m|m[1]+'//'+m[2]}||p).E}
  end

  def E; E.new self end
  def frag; split(/#/).pop() end
  def label; split(/[\/#]/)[-1] end
  def sh; Shellwords.escape self end

end
