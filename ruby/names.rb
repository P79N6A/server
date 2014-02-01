%w{cgi shellwords}.each{|r|require(r)}

class E

  # add hostname to URI (if missing)
  def hostURL e
    host = 'http://'+e['SERVER_NAME']
    if uri.index('/') == 0 
      host + uri
    else
      uri
    end
  end

  # URL to local data about global URI
  def localURL e
    if uri.index('/') == 0
      uri             # already a local path
    elsif e && uri.index('http://'+e['SERVER_NAME']+'/') == 0 
      pathSegment.uri # host match, unchanged local path
    else
      '/' + uri       # URI -> local path
    end
  end

  def appendURI u; E uri + u.to_s end
  def appendSlashURI u; E uri.t + u.to_s end
  def basename; File.basename path end
  def barename; basename.sub(/\.#{ext}$/,'') end
  def cascade; [self].concat parents end
  def concatURI b; container.appendURI b.E.shortPath end
  def container; @u ||= E[f ? dirname + '/.' + (File.basename path) : path] end
  def dirname; node.dirname.do{|d| d.to_s.size <= BaseLen ? '/' : d }.E end
  def docBase; uri.split(/#/)[0].E.do{|d| d.dirname.as d.bare } end
  def env r=nil; r ? (@r = r; self) : @r end
  def expand;   uri.expand.E end
  def ext;      File.extname(uri).tail||'' end
  def frag;     uri.frag end
  def label;    uri.label end
  def parent; E Pathname.new(uri).parent end
  def parents; parent.do{|p|p.uri.match(/^[.\/]+$/) ? [p] : [p].concat(p.parents)} end
  def path;    uri.match(/^\//) ? uri : ('/'+uri) end
  def pathSegment; uri.match(/^([a-z]+:\/\/[^\/]+)?(\/.*)/).do{|p|p[2]&&p[2].E}||nil end
  def prependURI u; E u.to_s + uri end
  def shorten;   uri.shorten.E end
  def shortPath; uri.match(/^\//) ? uri : ('/' + uri.shorten) end
  def == u;    to_s == u.to_s end
  def <=> c;   to_s <=> c.to_s end
  def sh;      d.force_encoding('UTF-8').sh end
  def to_s;    uri end
  def to_h;    {'uri' => uri} end

  alias_method :a, :appendURI
  alias_method :+, :appendURI
  alias_method :as, :appendSlashURI
  alias_method :base, :basename
  alias_method :bare, :barename
  alias_method :dir, :dirname
  alias_method :maybeURI, :uri
  alias_method :url, :uri

end

class Hash
  def uri
    self["uri"]||""
  end
  alias_method :url, :uri
  alias_method :maybeURI, :uri
  def label
    self[E::Label] || uri.label
  end
  def E
    E.new uri
  end
end

class String

  def dive
    self[0..2]+'/'+self[3..-1]
  end

  # expand CURIE
  Expand={}
  def expand
   (Expand.has_key? self) ?
    Expand[self] :
   (Expand[self] =
     match(/([^:]+):([^\/].*)/).do{|e|
      ( E::Prefix[e[1]] || e[1]+':' )+e[2]} || 
     self )
  end

  # shrink to CURIE
  def shorten
    E::Prefix.map{|p,f|
      return p + ':' + self[f.size..-1]  if (index f) == 0
    }
    self
  end

  def unpathFs
    self[E::BaseLen..-1].do{|p|
      (p.match(/^\/([a-z]+:)\/+(.*)/).do{|m|m[1]+'//'+m[2]}||p).E}
  end

  def unpath

    # HTTP URI
    if m = (match /^\/([a-z]+:)\/+(.*)/)
      (m[1] + '//' + m[2]).E

    # CURIE
    elsif m = (match /^\/([^\/:]+:[^\/]+)/)
      m[1].expand.E

    else
      self.E
    end

  end
  
  def E; E.new self end
  def frag; split(/#/).pop() end
  def label; split(/[\/#]/)[-1] end
  def sh; Shellwords.escape self end

end
