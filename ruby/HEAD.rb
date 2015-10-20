#watch __FILE__
class R

  AllowMethods = %w{GET PUT POST OPTIONS HEAD MKCOL DELETE PATCH}
  Allow = AllowMethods.join ', '

  def OPTIONS
    ldp
    method = @r['HTTP_ACCESS_CONTROL_REQUEST_METHOD']
    headers = @r['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']
    head = {'Access-Control-Allow-Methods' => (AllowMethods.member? method) ? method : Allow}
    head['Access-Control-Allow-Headers'] = headers if headers
    [200,(@r[:Response].update head), []]
  end

  def HEAD
    self.GET.
    do{| s, h, b |
       [ s, h, []]} # just Status + Headers
  end

  def setEnv r
    @r = r
    self
  end

  def getEnv; @r end
  alias_method :env, :getEnv

  ENV2RDF = -> env, graph { # environment -> graph
    # request resource
    subj = graph[env.uri] ||= {'uri' => env.uri, Type => R[BasicResource]}

    env['SERVER_SOFTWARE'] = 'https://gitlab.com/ix/pw'.R
    [env,
     env[:Links],
     env[:Response]].compact.map{|db|
      db.map{|k,v|
        subj[HTTP+k.to_s.sub(/^HTTP_/,'')] = v.class==String ? v.noHTML : v unless k.to_s.match /^rack/
      }}
  }

  def ldp
    @r[:Links][:acl] = aclURI
    @r[:Response].update({
#      'Accept-Patch' => 'application/ld+patch',
      'Accept-Post'  => 'application/ld+json, application/x-www-form-urlencoded, text/n3, text/turtle',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|(o.match HTTP_URI) && o } || '*',
      'Access-Control-Expose-Headers' => "User, Location, Link, Vary, Last-Modified",
      'Allow' => Allow,
      'MS-Author-Via' => 'SPARQL',
      'User' => [@r.user],
      'Vary' => 'Accept,Accept-Datetime,Origin,If-None-Match',
    })
    self
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
