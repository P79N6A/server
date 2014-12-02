watch __FILE__
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
    e.extend Th # add environment utils
    dev         # check for updated-source
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}   # canonical hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/,'.' # clean hostname
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/') rescue '/' # clean path
    path = Pathname.new(rawpath).expand_path.to_s          # interpret path
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'   # preserve trailing-slash
    resource = R[e['rack.url_scheme']+"://"+e['SERVER_NAME']+path] # resource instance
    e['uri'] = resource.uri                                # canonical URI to environment
    e[:Links] = [] ; e[:Response] = {}                     # response metadata
#    puts e.to_a.concat(e.q.to_a).map{|k,v|[k,v].join "\t"} # log request
    resource.setEnv(e).send(method).do{|s,h,b| # run request and inspect response
      R.log e,s,h,b # log response
      [s,h,b] } # return response
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    ua = e['HTTP_USER_AGENT'] || ''
    Stats[:agent][ua] ||= 0
    Stats[:agent][ua] += 1
    Stats[:status][s] ||= 0
    Stats[:status][s] += 1
    host = e['SERVER_NAME']
    Stats[:host][host] ||= 0
    Stats[:host][host] += 1
    mime = nil
    h['Content-Type'].do{|ct|
      mime = ct.split(';')[0]
      Stats[:format][mime] ||= 0
      Stats[:format][mime] += 1}
    puts [ e['REQUEST_METHOD'], s, '<'+e.uri+'>', h['Location'], '<'+e.user+'>', e['HTTP_REFERER'], mime
         ].compact.map(&:to_s).map(&:to_utf8).join ' '

  end

  ServerInfo = -> e,r {
    r.q['sort'] ||= 'stat:size'
    g = {}

    Stats.map{|sym, table|
      group = '#' + sym.to_s
      g[group] = {'uri' => group,
                  Type => R[Container],
                  LDP+'contains' => table.map{|key, count|

                    uri = case sym
                          when :agent
                            if u = key.match(Href)
                              u[0]
                            end
                          when :host
                            '//' + key + '/'
                          when :error
                            key.uri
                          else
                            '#' + rand.to_s.h
                          end

                    title = case sym
                            when :error
                              key[Title]
                            else
                              key
                            end

                    {'uri' => uri,
                     Label => title,
                     Stat+'size' => count }}}}

    [200,{'Content-Type' => r.format}, [Render[r.format].do{|p|p[g,r]} ||
      g.toRDF.dump(RDF::Writer.for(:content_type => r.format).to_sym)]]}

end
