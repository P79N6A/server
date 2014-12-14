class R

  def HEAD
    self.GET.
    do{| s, h, b |
       [ s, h, []]}
  end

  def setEnv r # set request-environment
    @r = r
    self
  end

  def getEnv; @r end # get request-environment

  alias_method :env, :getEnv

  def cors
    headers = {
      'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|(o.match HTTP_URI) && o } || '*',
    }
    @r[:Response].update headers
  end

  def ldp
    cors
    @r[:Links].concat ["<#{uri}>; rel=canonical",
                       "<#{aclURI}>; rel=acl",
                       "<#{docroot}>; rel=meta",
                       "<#{uri}>; rel=timegate",
                       "<http://www.w3.org/ns/ldp#Resource>; rel=type",
                      ]
    @r[:Links].push "<#{Container}>; rel=type" if @r[:container]

    headers = {
      'Accept-Patch' => 'application/ld+patch',
      'Accept-Post'  => 'application/ld+json, application/x-www-form-urlencoded, text/n3, text/turtle',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Expose-Headers' => "User, Triples, Location, Link, Vary, Last-Modified",
      'Allow' => Allow,
      'Link' => @r[:Links].intersperse(', ').join,
      'Vary' => 'Accept,Accept-Datetime,Origin,If-None-Match',
    }

    @r[:Response].update headers
  end

end

module Th

  def accept; @accept ||= accept_ end

  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      (k.split /,/).map{|e| # each pair
        f,q = e.split /;/   # split MIME from q value
        i = q && q.split(/=/)[1].to_f || 1.0 # q || default
        d[i] ||= []; d[i].push f.strip}} # append
    d
  end

  def linkHeader
    lh = {}
    self['HTTP_LINK'].do{|links|
      links.split(', ').map{|link|
        uri,rel = nil
        link.split(';').map{|a|
          a = a.strip
          if a[0] == '<' && a[-1] == '>'
            uri = a[1..-2]
          else
            rel = a.match(/\s*rel="?([^"]+)"?/)[1]
          end
        }
        lh[rel] = uri }}
    lh
  end

end
