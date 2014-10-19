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
    p = Pathname.new (URI.unescape e['REQUEST_PATH'].utf8).gsub /\/+/, '/' # path
    path = p.expand_path.to_s                              # interpret path
    path += '/' if path[-1] != '/' && p.to_s[-1] == '/'    # preserve trailing-slash
    resource = R[e['SCHEME']+"://"+e['SERVER_NAME']+path]  # resource
    e[:Links] = []                                         # response links
    e[:Response] = {Daemon: [R[Daemon]]}                   # response head
    e['uri'] = resource.uri                                # response URI
#    puts e.map{|k,v| [k,v].join ' '} # log request
    resource.setEnv(e).send(method).do{|s,h,b| 
      R.log e,s,h,b # log response
      [s,h,b] } # response
  rescue Exception => x
    E500[x,e]
  end

  def R.log e, s, h, b
    ua = e['HTTP_USER_AGENT'] || ''
    u = '#' + ua.slugify
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

    mime = h['Content-Type'].do{|t|t.split(';')[0]}
    Stats[:format] ||= {}
    Stats[:format][mime] ||= 0
    Stats[:format][mime] += 1

    puts [ e['REQUEST_METHOD'], s, '<'+e.uri+'>', h['Location'].do{|l| ['->','<'+l+'>'] }, '<'+e.user+'>', e['HTTP_REFERER'], mime
         ].compact.join ' '

  end

  GET['/stat'] = -> e,r {
    unless e.path.match(/^\/stat\/?$/)
      nil # pass through child paths
    else
    b = {_: :table,
      c: [{_: :tr, class: :head, c: {_: :td, colspan: 2, c: :status}},
          Stats[:status].sort_by{|_,c|-c}.map{|status, count|
            {_: :tr, c: [{_: :td, c: status}, {_: :td, class: :count, c: count}]}},

          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :domain}},
          Stats[:host].sort_by{|_,c|-c}.map{|host, count|
            {_: :tr, c: [{_: :td, class: :count, c: count}, {_: :td, c: {_: :a, href: '//'+host, c: host}}]}},

          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :MIME}},
          Stats[:format].sort_by{|_,c|-c}.map{|mime, count|
            {_: :tr, c: [{_: :td, class: :count, c: count}, {_: :td, c: mime}]}},

          {_: :tr, class: :head, c: {_: :td, colspan: 2, c: :agent}},
          Stats[:agent].values.sort_by{|a|-a[:count]}[0..48].map{|a|
            {_: :tr, c: [{_: :td, class: :count, c: a[:count]}, {_: :td, c: a[Title]}]}},

          {_: :style, c: ".count, tr.head > td {font-weight: bold}"}]}

    [200, {'Content-Type'=>'text/html'}, [H(b)]]
    end}

end
