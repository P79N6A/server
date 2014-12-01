#watch __FILE__
class R

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
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}   # use original hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/,'.' # host
    e['SCHEME'] = e['rack.url_scheme']                     # scheme
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') rescue '/'
    path = Pathname.new(rawpath).expand_path.to_s          # interpret path
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'   # preserve trailing-slash
    resource = R[e['SCHEME']+"://"+e['SERVER_NAME']+path]  # resource
    e[:Links] = []                                         # response links
    e[:Response] = {}                                      # response head
    e['uri'] = resource.uri                                # response URI
#    puts e.to_a.concat(e.q.to_a).map{|k,v|[k,v].join "\t"} # log request
    resource.setEnv(e).send(method).do{|s,h,b|
      R.log e,s,h,b # log response
      [s,h,b] } # response
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    ua = e['HTTP_USER_AGENT'] || ''
    Stats[:agent] ||= {}
    Stats[:agent][ua] ||= 0
    Stats[:agent][ua] += 1

    Stats[:status] ||= {}
    Stats[:status][s] ||= 0
    Stats[:status][s] += 1

    host = e['SERVER_NAME']
    Stats[:host] ||= {}
    Stats[:host][host] ||= 0
    Stats[:host][host] += 1

    mime = nil
    h['Content-Type'].do{|ct|
      mime = ct.split(';')[0]
      Stats[:format] ||= {}
      Stats[:format][mime] ||= 0
      Stats[:format][mime] += 1
    }

    puts [ e['REQUEST_METHOD'], s, '<'+e.uri+'>', h['Location'], '<'+e.user+'>', e['HTTP_REFERER'], mime
         ].compact.map(&:to_s).map(&:to_utf8).join ' '

  end

  WebCache = -> e,r {
    r[:container] = true if e.justPath.e
    r.q['set'] = 'cache'
    nil}

  FileSet['cache'] = -> re,q,g {
    FileSet['default'][re.justPath.setEnv(re.env),q,g].map{|r|
      r.host ? R['/domain/' + r.host + (r.path||'')].setEnv(re.env) : r }}

  ServerInfo = -> e,r {
    r.q['sort'] ||= 'stat:size'
    g = {}

    Stats.map{|k,v|
      group = '#' + k.to_s
      g[group] = {'uri' => group, Type => R[Container],
                                  LDP+'contains' => v.map{|key,count|
                    uri = case k
                          when :host
                            '//' + key + '/'
                          else
                            '#' + rand.to_s.h
                          end
                    {'uri' => uri, Title => key,
                     Stat+'size' => count }}}}
    
    [200, {'Content-Type'=>'text/html'}, [Render['text/html'][g,r]]]}

end
