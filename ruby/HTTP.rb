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
    e[:Response] = {Daemon: Daemon}                         # response head
    e['uri'] = resource.uri                                 # response URI

    resource.setEnv(e).send(method).do{|s,h,b| # call and inspect

      ua = e['HTTP_USER_AGENT']
      u = '#'+(ua||'').slugify
      Stats[:agent] ||= {}
      Stats[:agent][u] ||= {Title => ua.hrefs}
      Stats[:agent][u][:count] ||= 0
      Stats[:agent][u][:count] += 1

      Stats[:status] ||= {}
      Stats[:status][s] ||= 0
      Stats[:status][s] += 1

      host = e['SERVER_NAME']
      Stats[:host] ||= {}
      Stats[:host][host] ||= 0
      Stats[:host][host] += 1

      puts [ method, s, '<'+resource.uri+'>',
             *(e.user ? ['<'+e.user+'>'] : []), ua, e['HTTP_REFERER']
           ].join ' '

      [s,h,b] } # response
  rescue Exception => x
    E500[x,e]
  end

  GET['/stat'] = -> e,r {
    b = {_: :table,
      c: [{_: :tr, class: :head, c: {_: :td, colspan: 2, c: :domain}},

          Stats[:host].sort_by{|_,c|-c}.map{|host,count|
            {_: :tr, c: [{_: :td, class: :count, c: count},
                         {_: :td, c: {_: :a, href: '//'+host, c: host}}]}},
          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :status}},

          Stats[:status].map{|s,count|
            {_: :tr, c: [{_: :td, c: s},
                         {_: :td, class: :count, c: count}]}},
          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :agent}},

          Stats[:agent].values.sort_by{|a|-a[:count]}[0..48].map{|a|
            {_: :tr, c: [{_: :td, class: :count, c: a[:count]},
                         {_: :td, c: a[Title]}]}},

          {_: :style, c: "
a {text-decoration: none; font-size: 1.1em}
.count {font-weight: bold}
tr.head > td {font-weight: bold; font-size: 1.6em; padding-top: .3em}"}]}

    [200, {'Content-Type'=>'text/html'}, [H(b)]]}

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
