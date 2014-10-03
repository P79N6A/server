#watch __FILE__
class R

  Apache = ENV['apache'] # apache=true in shell-environment
  Nginx  = ENV['nginx']

  def setEnv r # set request-environment
    @r = r
    self
  end

  def getEnv # get request-environment
    @r
  end

  alias_method :env, :getEnv

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def R.call e
    method = e['REQUEST_METHOD']
    return [405, {'Allow' => Allow},[]] unless AllowMethods.member? method
    e.extend Th # add environment util-functions
    dev         # check sourcecode
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME']=h }  # use original hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.' # host
    e['SCHEME'] = e['rack.url_scheme']                      # scheme
    p = Pathname.new (URI.unescape e['REQUEST_PATH'].utf8).gsub /\/+/, '/'
    path = p.expand_path.to_s                               # path
    path += '/' if path[-1] != '/' && p.to_s[-1] == '/'     # preserve trailing-slash
    resource = R[e['SCHEME']+"://"+e['SERVER_NAME'] + path] # resource
    e[:Links] = []                                          # response links
    e[:Response] = {}                                       # response headers
    e['uri'] = resource.uri                                 # response URI

    resource.setEnv(e).send(method).do{|s,h,b|
      puts [ method,
             s,
             '<'+resource.uri+'>',
             *(e.user ? ['<'+e.user+'>'] : []),
             e['HTTP_USER_AGENT'],
             e['HTTP_REFERER'
              ]].join ' '
      [s,h,b]

    } # response
  rescue Exception => x
    E500[x,e]
  end

  def q
    @r.q # query Hash
  end

  def ldp
    headers = { 
      'Accept-Patch' => 'application/ld+patch',
      'Accept-Post'  => 'application/ld+json, application/x-www-form-urlencoded, text/n3, text/turtle',
      'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|(o.match HTTP_URI) && o } || '*',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Expose-Headers' => "User, Triples, Location, Link, Vary, Last-Modified",
      'Allow' => Allow,
      'Link' => @r[:Links].intersperse(', ').join,
    }
    @r[:Links].concat ["<#{aclURI}>; rel=acl",
                       "<#{metaURI}>; rel=meta"]
    @r[:Response].update headers
  end

end

module Th

  def cookies
    (Rack::Request.new self).cookies
  end

  def q
    @q ||=
      (if q = self['QUERY_STRING']
         h = {}
         q.split(/&/).map{|e| k, v = e.split(/=/,2).map{|x| CGI.unescape x }
                              h[k] = v }
         h
       else
         {}
       end)
  end

  def format
    @format ||= selectFormat
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

end

class Hash

  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

end

Rack::Utils::HTTP_STATUS_CODES[333] = "Returning Related"
Rack::Utils::SYMBOL_TO_STATUS_CODE[:returning_related] = 333

module Thin
  HTTP_STATUS_CODES ||= {}
  HTTP_STATUS_CODES[333] = "Returning Related"
end
