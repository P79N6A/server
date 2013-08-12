require 'element/W'
%w{GET HEAD POST PATCH uid 404 500
}.map{|i|require 'element/Th/' + i }
require 'rack'

class String
  # parse querystring
  def qp
    d={}
    split(/&/).map{|e|
      k,v=e.split(/=/,2).map{|x|
         CGI.unescape x}
      d[k]=v}
    d
  end
  def hR
    [200,{'Content-Type'=>'text/html'},[self]]
  end
end

module Tb
  def q
   @q ||= self.().qp
  end
end

module Th
  def qs
    (['GET','HEAD'].member? fn) ? self['QUERY_STRING'] : self['rack.input'].read
  end
  # read querystring
  def q
    @q ||= (qs||'').qp.do{|q|
      (q['?']).do{|d|
        E::F['?'][d].do{|g| # expand aliases
          g.merge q
        } || q } || q}
  end
  # read Accept header
  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      k.split(/,/).map{|e|
        f,q=e.split(/;/)
        i=q&&q.split(/=/)[1].to_f||1
        d[i]||=[]
        d[i].push f}}
    d
  end

  def format
    @format ||= conneg
  end

  def conneg
    # choose a preferred content-type
    return q['format'] if q['format'] && E::F[E::Render+q['format']]
    accept.sort.reverse.map{|p|p[1].map{|mime|
        return mime if E::F[E::Render+mime]
      }}
    'text/html'
  end

  def accept; @accept ||= accept_ end

  def fn
    # request method (Symbol) getter
    self['REQUEST_METHOD']
  end
end

class Hash
  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end
  def env r # thread environment through to children
    @r = r
    self
  end
end

class E

  F['?'] ||= {}

  # access or update request environment
  def env r=nil
    r ? (@r = r
         self) : @r
  end

  def E.call e
    dev         # check for changed source code
    e.extend Th # enable request-related utility functions
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h } # hostname
   (e['REQUEST_PATH'].force_encoding('UTF-8').do{|u|         # path
      CGI.unescape(u.index(Prefix)==0 ? u[Prefix.size..-1] : # non-local or non-HTTP URI
      'http://' + e['SERVER_NAME'] + u.gsub('+','%2B'))      # HTTP URI
    }.E.env(e).jail.do{|r|           # valid path?
      e['uri']=r.uri; r.send e.fn    # update URI and continue
    } || [403,{},['invalid path']]). # reject
      do{|response| puts             # inspect
        [e.fn, response[0],
        ['http://', e['SERVER_NAME'], e['REQUEST_URI']].join,
         e['HTTP_USER_AGENT'],e['HTTP_REFERER']].join ' '
        response }
    end

  # to run sans config.ru file
  # RACK_ENV=production E daemon -s thin -p 80
  def E.daemon *a; ARGV.shift
    Rack::Server.start Rack::Server.new.options.update({app: E})
  end

  # site-specific code

  E['http:/*/*.rb'].glob.map{|s| puts "site config #{s}"
    require s.d}

end
