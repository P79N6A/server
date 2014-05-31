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

  def lateHost; R[@r['SCHEME']+'://'+@r['SERVER_NAME']+'/'] end

  def R.call e
    e.extend Th # add HTTP utility functions
    dev         # check watched source
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'
    e['SCHEME'] = "http" + (e['HTTP_X_FORWARDED_PROTO'] == 'https' ? 's' : '')
    p = Pathname.new CGI.unescape e['REQUEST_PATH'].force_encoding 'UTF-8'
    path = p.expand_path.to_s # interpret path
    path += '/' if path[-1] != '/' && p.to_s[-1] == '/' # preserve trailing-slash
    resource = R[e['SCHEME'] + "://" + e['SERVER_NAME'] + path]
    e[:Links] = []; e[:Response] = {}
    resource.setEnv(e).send(e['REQUEST_METHOD']).do{|s,h,b|
      puts [s,resource+e['QUERY_STRING'].do{|q|q.empty? ? '' : '?'+q},
            h['Content-Type'], e['HTTP_ACCEPT'], e['HTTP_USER_AGENT'],
            e['HTTP_REFERER']].join ' ' unless s==404
      [s,h,b]}
  rescue Exception => x
    E500[x,e]
  end

  def q
    @r.q # if q not otherwise bound it's a single-char shortcut to query-string Hash
  end

  E404 = -> e,r,g=nil {
    g ||= {}            # graph
    s = g[e.uri] ||= {} # resource
    path = e.justPath
    s[Title] = '404'
    s[RDFs+'seeAlso'] = [e.parent, path.a('*').glob, e.a('*').glob] unless path.to_s == '/'
    s['#query'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    s[Header+'accept'] = r.accept
    %w{CHARSET LANGUAGE ENCODING}.map{|a| s[Header+'accept-'+a.downcase] = r.accept_('_'+a)}
    r.map{|k,v|
      s[Header+k.to_s.sub(/^HTTP_/,'').downcase.gsub('_','-')] = v unless [:Links,:Response].member?(k)}
    r.q['view'] = 'HTML'
    [404,{'Content-Type'=> 'text/html'},[Render['text/html'][g,r]]]}

  Errors = {}

  GET['/500'] = -> e,r { 
    r[:Response]['ETag'] = Errors.keys.sort.h
    e.condResponse ->{Render['text/html'][Errors, r]}}

  E500 = -> x,e {
    uri = e['SERVER_NAME']+e['REQUEST_URI']
    dump = [500, uri, x.class, x.message, x.backtrace[0..6]].flatten.map(&:to_s)
    Errors[uri] ||= {'uri' => '//'+uri, Content => dump.map(&:hrefs).join('<br>')}; $stderr.puts dump

    [500,{'Content-Type'=>'text/html'},
     [H[{_: :html,
          c: [{_: :head,c: [{_: :title, c: 500},(H.css '/css/500')]},
              {_: :body,
                c: [{_: :h1, c: 500},
                    {_: :table,
                      c: [{_: :tr,c: [{_: :td, c: {_: :b, c: x.class}},{_: :td, class: :message, colspan: 2, c: x.message.hrefs}]},
                          x.backtrace.map{|f| p = f.split /:/, 3
                            {_: :tr,
                              c: [{_: :td, class: :path, c: p[0].R.abbr},
                                  {_: :td, class: :index, c: p[1]},
                                  {_: :td, class: :context, c: (p[2]||'').hrefs}].cr}}.cr]}]}]}]]]}
  def OPTIONS
    [200,
     {'Access-Control-Allow-Methods' => 'GET, PUT, POST, OPTIONS, HEAD, MKCOL, DELETE, PATCH',
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o} || '*',
       'Access-Control-Allow-Credentials' => 'true',
       'Allow' => 'GET, PUT, POST, OPTIONS, HEAD, MKCOL, DELETE, PATCH',
       'Accept-Patch' => 'application/json',
       'Accept-Post' => 'text/turtle,text/n3,application/json'},[]]
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

  def selectFormat

    { '.html' => 'text/html',         # format-variant URI suffix
      '.json' => 'application/json',
      '.nt' => 'text/plain',
      '.n3' => 'text/n3',
      '.rdf' => 'application/rdf+xml',
      '.ttl' => 'text/turtle',
    }[File.extname(self['REQUEST_PATH'])].do{|mime|
      return mime}

    accept.sort.reverse.map{|q,mimes| # Accept q-values descending
      mimes.map{|mime|
        return mime if RDF::Writer.for(:content_type => mime)}}

#    'text/n3'
    'text/html'
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
