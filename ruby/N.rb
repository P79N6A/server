%w{base64 cgi shellwords}.each{|r|require(r)}

def E e
  return e if e.class == E
  return nil unless e
  E.new e
end

class E

  def E.[] u; E u end

  def E uri=nil
    if uri
      E.new uri
    else
      self
    end
  end
  
  attr_reader :uri
  def initialize uri
    @uri = uri.to_s
  end
  def uri= u
    @uri = u
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
    uri.split(/#/)[0].E.do{|d|
      d.dirname.as d.bare }
  end
  
  # same as above, but w/ URI errors
  def docBaseURI
    u = URI uri
    s = u.scheme
    p = u.path
    p = '/' if p.empty?
    ((s ? s + '://' : '') + # scheme
     u.host +               # host
     File.dirname(p).t +    # path
     File.basename(p)[0..-(File.extname(p).size+1)]).E # doc
  end

  def frag
    uri.frag
  end

  def docs
    doc = self if e # directly-referenced doc
    docs = docBase.glob ".{e,html,n3,nt,owl,rdf,ttl}" # basename-sharing docs
    dir = (d? && uri[-1]=='/' && uri.size>1) ? c : [] # trailing slash descends
    [doc,docs,dir].flatten.compact
  end

  def dirname
    n = node.dirname
    n = '/' if !n || n.to_s.size <= BaseLen
    n.E
  end
  
  # local URL from unlocatable identifier (mail MSGID, etc)
  def url
    path? ? uri : Prefix + (CGI.escape uri)
  end

  # local URL even if locatable-identifier
  def localURL e
    # path
    if uri.index('/') == 0
      uri
    # host match
    elsif uri.index('http://'+e['SERVER_NAME']) == 0
      pathSegment.uri
    # non-local
    else
      Prefix + (CGI.escape uri)
    end
  end

  def pathSegment
    m = uri.match(/^([a-z]+:\/\/[^\/]+)?(\/.*)/)
    m && m[2] && m[2].E || self
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

  def concatURI b
    if b
      u.a b.E.path
    else
      self
    end
  end

  def prependURI s
    _ = dup
    _.uri = s + uri
    _
  end

  def appendURI s
    _ = dup
    _.uri = uri + s
    _
  end

  alias_method :a, :appendURI
  alias_method :+, :appendURI

  def appendSlashURI s
    _ = dup
    _.uri = uri.t + s
    _
  end

  alias_method :as, :appendSlashURI

  def path?
    uri.path?
  end

  def opaque
    @opaque = true
    self
  end

  def opaque?
    @opaque
  end

  # URI to fs-path
  def path
    @path ||=
      (if path?
         if uri.match /^\//
           uri
         else
           '/' + uri
         end
       else
         if uri.match(/\//) || @opaque
           '/E/' + uri.h.dive[0..5] + (Base64.urlsafe_encode64 uri)
         else
           '/u/' + uri
         end
       end)
  end

  def u
    @u ||= E (f ? dirname + '/.' + File.basename(path) : path.t + E::S)
  end

  # (_ _ o) -> o
  def ro
    uri.split(/#{E::S}/)[-1].unpath
  end

  def sh
    d.force_encoding('UTF-8').sh
  end

  # literals to URIs

  def E.literal o
    E['/'].literal o
  end

  def literal o

    # already a URI
    return self if o.class == E

    # blob for non-strings
    return literalBlob o unless o.class == String

    # whitelisted predicateURIs to paths
    return literalURI o if (Literal[uri] || o.size<=88) && !o.match(/\//)

    # string matches URI format
    return E o if o.match %r{\A[a-z]+://[^\s]+\Z}

    # blob
    literalBlob o

  end

  # pathname for short literals
  def literalURI o
    E "/l/"+(Literal[uri] && o.gsub(/[\.:\-T+]/,'/'))+'/'+o
  end
 
  def literalBlobURI o
    if o.class == String
      E "/E/blob/"+o.h.dive
    else
      E "/E/json/"+[o].to_json.h.dive
    end
  end

  def literalBlob o
    u = literalBlobURI o
    u.w o, !o.class == String unless u.f
  end

  # spaceship
  def <=> c
    to_s <=> c.to_s
  end

  def to_s
    uri
  end

  def to_h
   {'uri' => uri}
  end

end

class Hash
  def uri
    self["uri"]
  end
  def url; self.E.url end
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

  # expand qname-style identifier to URI
  Expand={}
  def expand
    # memoize lookups
   (Expand.has_key? self) ?
    Expand[self] :
   (Expand[self] =
     match(/([^:]+):([^\/].*)/).do{|e|
       (E::Abbrev[e[1]]||e[1]+':')+e[2]} || 
     self )
  end

  def sh
    Shellwords.escape self
  end

  # full FS path -> URI
  def unpathURI
    self[E::BaseLen..-1].do{|p|
      (p.match(/^\/([a-z]+:)\/+(.*)/).do{|m|m[1]+'//'+m[2]}||p).E}
  end

  # path -> URI || literal
  def unpath

    # URL
    if m = (match /^\/([a-z]+:)\/+(.*)/)
      (m[1] + '//' + m[2]).E

    # String literal
    elsif match /^\/E\/blob/
      self.E.r

    # JSON literal
    elsif match /^\/E\/json/
      self.E.r true

    # String literal in basename
    elsif match /^\/l\//
      File.basename self

    # URI in basename
    elsif match /^\/u\//
     (File.basename self).E

    # opaque URI
    elsif match /^\/E\/..\//
      self[9..-1].match(/([^.]+)(.*)/).do{|c|
        (Base64.urlsafe_decode64 c[1]) + c[2]
      }.E

    else
      self.E
    end
  end
  
  def E
    E.new self
  end

  def path?
    (match /^(\.|\/|https?:\/)/) && true || false
  end

  def frag
    split(/#/).pop()
  end

  def label
    split(/[\/#]/)[-1]
  end

end
