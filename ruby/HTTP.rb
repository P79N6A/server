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

  def R.call e
    e.extend Th # add HTTP utility functions
    dev         # check watched source
    e['HTTP_X_FORWARDED_HOST'].do{|h| e['SERVER_NAME'] = h }
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'
    path = (Pathname.new CGI.unescape e['REQUEST_PATH'].force_encoding 'UTF-8').expand_path.to_s
    resource = R["http#{e['HTTP_X_FORWARDED_PROTO'] == 'https' ? 's' : ''}://" + e['SERVER_NAME'] + path]
    e[:Links] = []
    e[:Response] = {'URI' => resource.uri}
    resource.setEnv(e).send(e['REQUEST_METHOD']).do{|status,headers,body|
      puts [status,resource,headers['Content-Type'],e['HTTP_USER_AGENT'],e['HTTP_REFERER']].join ' '
      [status,headers,body]}
  rescue Exception => x
    E500[x,e]
  end

  def q; @r.q end

  E404 = -> e,r,g=nil {
    g ||= {} # graph
    s = g[e.uri] ||= {} # resource
    path = e.justPath
    s[Title] = '404'
    s[RDFs+'seeAlso'] = [e.parent, path.a('*').glob, e.a('*').glob] unless path.to_s == '/'
    s['#query'] = Hash[r.q.map{|k,v|[k.to_s.hrefs,v.to_s.hrefs]}]
    s[Header+'accept'] = r.accept
    %w{CHARSET LANGUAGE ENCODING}.map{|a| s[Header+'accept-'+a.downcase] = r.accept_('_'+a)}
    r.map{|k,v|
      s[Header+k.to_s.sub(/^HTTP_/,'').downcase.gsub('_','-')] = v unless [:Links,:Response].member?(k)
    }
    r.q.delete 'view' unless r.q['view']=='edit'
    [404,{'Content-Type'=> r.format},[Render[r.format][g,r]]]}

  Errors = {}

  GET['/500'] = -> e,r { 
    r[:Response]['ETag'] = Errors.keys.sort.h
    e.condResponse ->{Render[r.format][Errors, r]}}

  E500 = -> x,e {
    where = e['SERVER_NAME'] + e['REQUEST_URI']
    $stderr.puts [500, where, x.class, x.message].join ' '
    Errors[where] ||= {'uri' => '//'+where, Content => [x.class, x.message,x.backtrace[0..2]].flatten.join('<br>')}

    [500,{'Content-Type'=>'text/html'},
     [H[{_: :html,
          c: [{_: :head,c: [{_: :title, c: 500},(H.css '/css/500')]},
              {_: :body,
                c: [{_: :h1, c: 500},
                    {_: :table,
                      c: [{_: :tr,c: [{_: :td, c: {_: :b, c: x.class}},{_: :td, class: :space},{_: :td, class: :message, c: x.message.hrefs}]},
                          x.backtrace.map{|f| p = f.split /:/, 3
                            {_: :tr,
                              c: [{_: :td, class: :path, c: p[0].R.abbr},
                                  {_: :td, class: :index, c: p[1]},
                                  {_: :td, class: :context, c: (p[2]||'').hrefs}].cr}}.cr]}]}]}]]]}
  def OPTIONS
    [200,
     {'Access-Control-Allow-Methods' => 'GET, PUT, POST, OPTIONS, HEAD, MKCOL, DELETE, PATCH',
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o} || '*',
       'Allow' => 'GET, PUT, POST, OPTIONS, HEAD, MKCOL, DELETE, PATCH',
       'Accept-Patch' => 'application/json',
       'Accept-Post' => 'text/turtle;charset=utf-8,text/n3;charset=utf-8,text/nt;charset=utf-8,text/css;charset=utf-8,text/html;charset=utf-8,text/javascript;charset=utf-8,text/plain;charset=utf-8,application/rdf+xml;charset=utf-8,application/json;charset=utf-8,image/jpeg,image/jpeg,image/png,image/gif,font/otf'},[]]
  end

end

module Th

  def q
    @q ||=
      (if q = self['QUERY_STRING']
         h = {}
         q.split(/&/).map{|e| k,v = e.split(/=/,2).map{|x| CGI.unescape x }
                              h[k] = v }
         h
       else
         {}
       end)
  end

  # Accept -> Hash
  def accept_ k=''
    d={}
    self['HTTP_ACCEPT'+k].do{|k|
      (k.split /,/).map{|e| # each pair
        f,q = e.split /;/   # split MIME from q value
        i = q && q.split(/=/)[1].to_f || 1.0
        d[i] ||= []; d[i].push f.strip}} # append
    d
  end

  def format
    @format ||= conneg
  end

  def conneg

    # explicit URI of format-variant
    {
      '.atom' => 'application/atom+xml',
      '.html' => 'text/html',
      '.json' => 'application/json',
      '.jsonld' => 'application/ld+json',
      '.nt' => 'text/ntriples',
      '.n3' => 'text/n3',
      '.rdf' => 'application/rdf+xml',
      '.ttl' => 'text/turtle',
      '.txt' => 'text/plain',
    }[File.extname(self['REQUEST_PATH'])].do{|mime|
      return mime}

    accept.sort.reverse.map{|q,mimes| # descending q-values
      mimes.map{|mime|
        return mime if R::Render[mime] || RDF::Writer.for(:content_type => mime)}}

    'text/html'
  end

  def accept; @accept ||= accept_ end

end

class Hash

  # TODO move to R.qs
  def qs
   '?'+map{|k,v|k.to_s+'='+(v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('')
  end

end
