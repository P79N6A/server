#watch __FILE__
class R

  Apache = ENV['apache'] # apache=true in shell-environment
  Nginx  = ENV['nginx']

  def setEnv r # request environment - Hash of HTTP Headers from Rack
    @r = r
    self
  end

  def getEnv
    @r
  end
  alias_method :env, :getEnv

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def bindHost # bind host to path
    return self if !hierPart.match(/^\//)
    R[(lateHost.join uri).to_s]
  end
  def lateHost; R[@r['SCHEME']+'://'+@r['SERVER_NAME']+'/'] end

  def R.call e
    e.extend Th # environment-scoped functions
    dev
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }                   # restore original hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'                    # remove .. and / from hostname
    e['SCHEME'] = "http" + (e['HTTP_X_FORWARDED_PROTO'] == 'https' ? 's' : '') # set scheme attribute in environment
    p = Pathname.new CGI.unescape e['REQUEST_PATH'].force_encoding 'UTF-8'     # instantiate Path
    path = p.expand_path.to_s                                                  # interpret path-segment
    path += '/' if path[-1] != '/' && p.to_s[-1] == '/'                        # restore trailing-slash
    resource = R[e['SCHEME'] + "://" + e['SERVER_NAME'] + path]                # init Resource
    e[:Links] = []; e[:Response] = {}                                          # init Response-header
    resource.setEnv(e).send(e['REQUEST_METHOD']).do{|s,h,b|                    # call HTTP method
     puts [s,resource+e['QUERY_STRING'].do{|q|q.empty? ? '' : '?'+q}, h['Content-Type'], e['HTTP_USER_AGENT'], e['HTTP_REFERER']].join ' ' unless s==404
      [s,h,b]} # Response
  rescue Exception => x
    E500[x,e]
  end

  def q
    @r.q # query Hash
  end

end

module Th

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

  def accept; @accept ||= accept_ end

  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      (k.split /,/).map{|e| # each pair
        f,q = e.split /;/   # split MIME from q value
        i = q && q.split(/=/)[1].to_f || 0.999 # favor specified q.1
        d[i] ||= []; d[i].push f.strip}} # append
    d
  end

  def graphResponse graph
    [200,
     {'Content-Type' => format + '; charset=UTF-8',
      'Triples' => graph.size.to_s,
       'Access-Control-Allow-Origin' => self['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o} || '*',
     },
     [(format == 'text/html' &&
    q['view'] == 'tabulate') ? H[R::View['tabulate'][]] :
      graph.dump(RDF::Writer.for(:content_type => format).to_sym)]]
  end

  def htmlResponse m
    [200,{'Content-Type'=> 'text/html; charset=UTF-8'},[R::Render['text/html'][m, self]]]
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
