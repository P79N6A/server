%w{base64 cgi shellwords}.each{|r|require(r)}

def E e
  return e if e.class == E
  return e unless e
  E.new e
end

class E
  def E.[] u; E u end
  def E e=uri; super e end

                      attr_reader :uri
  def initialize uri; @uri = uri.to_s end
  
  def base
    File.basename path
  end

  def bare
    base.sub(/\.#{ext}$/,'')
  rescue
    base
  end
  
  def ef;  @ef ||= docBase.a('.e') end
  def nt;  @nt ||= docBase.a('.nt') end
  def ttl; @ttl ||= docBase.a('.ttl') end
  
  # base URI for document
  # /concept <> /concept.ttl
  def docBase
    readlink.uri.split(/#/)[0].E.do{|d| d.dirname.as d.bare }
  end
  
  # usually same as above, but strict
  # fails on exotic/non-conforming URIs
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
    (e ? [self] : []). # directly-referenced
      concat(docBase.glob ".{e,html,n3,nt,owl,rdf,ttl}"). # docs
      concat((d? && uri[-1]=='/' && uri.size>1) ? c : []) # trailing slash -> children
  end

  def dirname
    no.dirname.E
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
    uri.match(/^([a-z]+:\/\/[^\/]+)?(\/.*)/)[2].do{|p| p.E } || self
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
    u.a E(b).path
  end

  def prependURI s
    (s + uri).E
  end

  def appendURI s
    (uri + s).E
  end

  alias_method :a, :appendURI
  alias_method :+, :appendURI

  def appendSlashURI s
    E uri.t + s
  end

  alias_method :as, :appendSlashURI

  # path? :: E -> Bool
  def path?
    uri.path?
  end

  # path :: E -> String
  def path
    @path ||=
      path? ? (uri.match(/^\//) ? 
               uri : '/'+uri) :
      '/E/'+uri.h.dive[0..5]+(Base64.urlsafe_encode64 uri)
  end

  def u
    @u ||= E (f ? dirname + '/.' + File.basename(path) : path.t + E::S)
  end

  # E (_ _ o) -> E o
  def ro
    uri.split(/#{E::S}/)[-1].unpath
  end

  def sh
    d.force_encoding('UTF-8').sh
  end

  # literal -> URI
  # optional "self" argument of Predicate for domain-specific ObjectURI hinting
  def E.literal o; E['/'].literal o end
  def literal o

    # already a URI
    return self if o.class == E

    # blob for non-strings
    return literalBlob o unless o.class == String

    # whitelisted-predicate URIs to paths
    return literalURI o if (Literal[uri] || o.size<=88) && !o.match(/\//)

    # string matches URI format
    return E o if o.match %r{\A[a-z]+://[^\s]+\Z}

    # blob
    literalBlob o

  end

  # pathname for short literals
  def literalURI o
    E "/u/"+(Literal[uri] && o.gsub(/[\.:\-T+]/,'/'))+'/'+o
  end
 
  def literalBlobURI o
    if o.class == String
      E "/blob/"+o.h.dive
    else
      E "/json/"+[o].to_json.h.dive
    end
  end

  # spaceship
  def <=> c
    to_s <=> c.to_s
  end

  # example: E('wiggly').to_s -> "wiggly"
  def to_s # string
    uri
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

  BaseLen  = E::FSbase.size

  def pathToURI
    self[BaseLen..-1].unpath
  end

  # string -> E || literal
  def unpath

    if m=(match /^\/([a-z]+:)\/+(.*)/) # URL
      (m[1]+'//'+m[2]).E

    elsif match /^\/blob/ # string
      self.E.r

    elsif match /^\/json/ # JSON
      self.E.r(true)

    elsif match /^\/u\// # trie
      File.basename self

    elsif match /^\/E\/..\/..\// # opaque URI
      self[9..-1].match(/([^.]+)(.*)/).do{|c|
        (Base64.urlsafe_decode64 c[1]) + c[2]
      }.E
    else # path
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
