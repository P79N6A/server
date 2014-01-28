%w{cgi shellwords}.each{|r|require(r)}

class E

  attr_reader :uri
  alias_method :url, :uri
  alias_method :maybeURI, :uri

  def env r=nil
    r ? (@r = r
         self) : @r
  end

  def == u
      to_s == u.to_s
  end

  def basename
    File.basename path
  end
  alias_method :base, :basename

  def barename
    basename.sub(/\.#{ext}$/,'')
  rescue
    basename
  end
  alias_method :bare, :barename

  def ef;  @ef ||= docBase.a('.e') end
  def nt;  @nt ||= docBase.a('.nt') end
  def ttl; @ttl||= docBase.a('.ttl') end

  def docBase
    !uri.empty? && uri.split(/#/)[0].do{|u|u.E.do{|d| d.dirname.as d.bare }} || E['']
  end

  def frag
    uri.frag
  end

  def parent
    E Pathname.new(uri).parent
  end

  def parents
    parent.do{|p|
      p.uri.match(/^[.\/]+$/) ? [p] : [p].concat(p.parents)}
  end

  def cascade
    [self].concat parents
  end

  def dirname
    n = node.dirname
    n = '/' if n.to_s.size <= BaseLen
    n.E
  end
  alias_method :dir, :dirname

  # add hostname to URI (if missing)
  def hostURL e
    host = 'http://'+e['SERVER_NAME']
    if uri.index('/') == 0 
      host + uri
    else
      uri
    end
  end

  # pointer to local data about global URI
  def localURL e
    if uri.index('/') == 0
      uri             # already a local path
    elsif e && uri.index('http://'+e['SERVER_NAME']+'/') == 0 
      pathSegment.uri # host match, unchanged local path
    else
      '/' + uri       # URI -> local path
    end
  end

  def pathSegment
    m = uri.match(/^([a-z]+:\/\/[^\/]+)?(\/.*)/)
    m && m[2] && m[2].E || nil
  end

  # URI extension :: E -> string
  def ext
    File.extname(uri).tail||''
  end

  def label
    uri.label
  end

  def expand
    uri.expand.E
  end

  def shorten
    uri.shorten.E
  end

  def prependURI u
    E u.to_s + uri
  end

  def appendURI u
    E uri + u.to_s
  end

  def appendSlashURI u
    E uri.t + u.to_s
  end

  def concatURI b
    u.appendURI b.E.shortPath
  end

  alias_method :a, :appendURI
  alias_method :+, :appendURI
  alias_method :as, :appendSlashURI

  def shortPath
    @shortPath ||=
      (if uri.match /^\//
         uri
       else
         '/' + uri.shorten
       end)
  end

  # URI -> path
  def path
    @path ||=
      (if uri.match /^\//
         uri
       else
         '/' + uri
       end)
  end

  def u
    # metadata storage-path of resource
    @u ||= E (f ? dirname + '/.' + (File.basename path) : path.t + '._')
  end

  # (_ _ o) -> o
  def innerPath
    (uri.split S)[-1].unpath
  end
  alias_method :ro, :innerPath

  def sh
    d.force_encoding('UTF-8').sh
  end

  def E.literal o
    ''.E.literal o
  end

  def literal o
    return o if o.class == E
    u = (if o.class == String
           E "/E/blob/"+o.h.dive
         else
           E "/E/json/"+[o].to_json.h.dive
         end)
    u.w o, !o.class == String unless u.f
    u
  end

  # spaceship comparison-operator
  def <=> c
    to_s <=> c.to_s
  end

  def to_s
    uri
  end

  def to_h
   {'uri' => uri}
  end

  # internal pathnames not on the web (cached representations, index databases)
  F['/E/GET'] = F[E404]

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

class Array
  def E
    self[0].E if self[0].class==Hash
  end
end

class String
  def dive
    self[0..1]+'/'+
    self[2..3]+'/'+
    self[4..-1]
  end

  # expand qname/CURIE-style identifier to URI
  Expand={}
  def expand
   (Expand.has_key? self) ?
    Expand[self] :
   (Expand[self] =
     match(/([^:]+):([^\/].*)/).do{|e|
      ( E::Prefix[e[1]] || e[1]+':' )+e[2]} || 
     self )
  end

  # shrink URI to qname/CURIE/prefixed identifier
  def shorten
    E::Prefix.map{|p,f|
      return p + ':' + self[f.size..-1]  if (index f) == 0
    }
    self
  end

  def sh
    Shellwords.escape self
  end

  def unpathFs
    self[E::BaseLen..-1].do{|p|
      (p.match(/^\/([a-z]+:)\/+(.*)/).do{|m|m[1]+'//'+m[2]}||p).E}
  end

  # path -> URI || literal
  def unpath

    # HTTP URI
    if m = (match /^\/([a-z]+:)\/+(.*)/)
      (m[1] + '//' + m[2]).E

    # prefix-shortened URI
    elsif m = (match /^\/([^\/:]+:[^\/]+)/)
      m[1].expand.E

    # String literal
    elsif match /^\/E\/blob/
      self.E.r

    # JSON literal
    elsif match /^\/E\/json/
      self.E.r true

    # plain path
    else
      self.E
    end

  end
  
  def E
    E.new self
  end

  def frag
    split(/#/).pop()
  end

  def label
    split(/[\/#]/)[-1]
  end

end
