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

  def docBase
    readlink.uri.
      split(/#/)[0].E.
      do{|d|d.dirname.as d.bare}
  end

  def docBaseURI
    u=URI uri; s=u.scheme
    p=u.path; p = '/' if p.empty?
    ((s ?s+'://':'') + u.host + File.dirname(p).t + File.basename(p)[0..-(File.extname(p).size+1)]).E
  end

  def frag
    uri.frag
  end

  def docs
    [self].
      concat(docBase.glob ".{e,html,n3,nt,owl,rdf,ttl}"). # docs
      concat((d? && uri[-1]=='/') ? c : []) # trailing slash -> children
  end

  def dirname
    no.dirname.E
  end
  
  # generate URL for non-URL identifier (mail ID, Tag URI..)
  def url
    path? ? uri : Prefix + (CGI.escape uri)
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

  # cons URIs
  # s :: E -> E
  def s b
    u.a E(b).path
  end

  # prepend on URI
  # prepend :: String -> E
  def prepend s
    (s + uri).E
  end

  # append on URI
  # a :: String -> E
  def a s
    (uri + s).E
  end
  alias_method :+, :a

  # append on URI - after slash
  # as :: String -> E
  def as s
    E uri.t+s
  end

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
    uri.split(/#{E::S}\//)[-1].unpath
  end

  def sh
    d.force_encoding('UTF-8').sh
  end

  # literal -> URI
  def literal o
    return literalBlob o unless o.class == String
    return literalURI o if (Literal[uri] || o.size<=88) && !o.match(/\//)
    return E o if o.match %r{\A[a-z]+://[^\s]+\Z}
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
    self[0..1]+'/'+self[2..3]+'/'+self[4..-1]
  end

  Expand={}
  def expand
    (Expand.has_key? self) ? Expand[self] : (Expand[self] =
     match(/([^:]+):([^\/].*)/).do{|e|
       (E::Abbrev[e[1]]||e[1]+':')+e[2]} || 
     self)
  end

  def sh
    Shellwords.escape self
  end

  # string -> E || literal
  def unpath r=true

    if m=(match /^([a-z]+:)\/+(.*)/) # URL
      (m[1]+'//'+m[2]).E

    elsif match /^blob/ # string
      r ? ('/'+self).E.r : ('/'+self).E

    elsif match /^json/ # JSON
      r ? (('/'+self).E.r true) : ('/'+self).E

    elsif match /^u\// # trie
      r ? (File.basename self) : ('/'+self).E

    elsif match /^E\/..\/..\// # encoded URI
      Base64.urlsafe_decode64(self[8..-1]).E

    else # path
      ('/'+self).E
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
    frag.gsub('_',' ')
  end
end
