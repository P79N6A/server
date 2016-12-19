# coding: utf-8
#watch __FILE__

module Rack
  module Adapter
    # load this config so "config.ru" file doesnt need to exist
    def self.guess _; :rack end
    def self.load _
      Rack::Builder.new {
        use Rack::Deflater # gzip response
        run R              # call R.call
      }.to_app
    end
  end
end

class R

  AllowMethods = %w{HEAD GET PUT PATCH POST OPTIONS DELETE}
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
       [ s, h, []]}
  end

  def setEnv r
    @r = r
    self
  end

  def env
    @r
  end

  def ldp
    @r[:Links][:acl] = aclURI
    @r[:Response].update({
      'Accept-Patch' => 'application/ld+patch, application/sparql-update',
      'Accept-Post'  => 'application/ld+json, application/x-www-form-urlencoded, text/turtle',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|(o.match HTTP_URI) && o } || '*',
      'Access-Control-Expose-Headers' => "User, Location, Link, Vary, Last-Modified",
      'Allow' => Allow,
      'MS-Author-Via' => 'SPARQL',
      'User' => [user],
      'Vary' => 'Accept,Accept-Datetime,Origin,If-None-Match',
    })
    self
  end

  # coax output through thin/foreman/shell buffers
  $stdout.sync = true
  $stderr.sync = true

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def R.call e
    return [405,{'Allow' => Allow},[]] unless AllowMethods.member? e['REQUEST_METHOD']
    return [400,{},[]] if e['REQUEST_PATH'].match(/\.php$/i)
    dev
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/, '.'
    rawpath = URI.unescape(e['REQUEST_PATH'].utf8).gsub(/\/+/,'/')
    path = Pathname.new(rawpath).expand_path.to_s
    # preserve trailing-slash
    path += '/' if path[-1] != '/' && rawpath[-1] == '/'
    # resource URI
    resource = R[e['rack.url_scheme'] + "://" + e['SERVER_NAME'] + path]
    e['uri'] = resource.uri
    # response header
    e[:Links] = {}
    e[:Response] = {}
    e[:filters] = []
    # continue call on actual resource
    resource.setEnv(e).send(e['REQUEST_METHOD']).do{|s,h,b|
      puts [resource.uri, h['Location'] ? ['->',h['Location']] : nil, '<'+resource.user_id+'>', resource.format, e['HTTP_REFERER'], e['HTTP_USER_AGENT']].
             flatten.compact.map(&:to_s).join ' '
      [s,h,b]}
  rescue Exception => x
   [500,{'Content-Type' => 'text/plain'},[[x.class,x.message,x.backtrace].join("\n")]]
  end

  def R.parseQS qs
    h = {}
    qs.split(/&/).map{|e|
      k, v = e.split(/=/,2).map{|x| CGI.unescape x }
      h[(k||'').downcase] = v }
    h
  end

  def notfound
    graph = {}
    this = graph[uri] = {'uri' => uri, Type => R[BasicResource]}
    seeAlso = this[RDFs+'seeAlso'] = []
    cascade.reverse.map{|p|p.e && seeAlso.push(p)}
    env[:search] = true
    [env, env[:Links], env[:Response]].compact.map{|db|
      db.map{|k,v|
        this[HTTP+k.to_s.sub(/^HTTP_/,'')] = v.class==String ? v.noHTML : v unless k.to_s.match /^rack/ }}
    [404,{'Content-Type' => format},
     [Render[format].do{|fn|fn[graph,self]} ||
      graph.toRDF(self).dump(RDF::Writer.for(:content_type => format).to_sym, :prefixes => Prefixes)]]
  end

  ViewGroup[User] = -> g,env {
    if env.signedIn
      g.map{|u,r|
        {style: "border-radius: 2em; background-color:#eee;color:#000;display:inline-block",
         c: [{_: :a, class: :user, style: "font-size: 3em;text-decoration:none",
              href: "http://linkeddata.github.io/profile-editor/#/profile/view?webid=" + CGI.escape(u)}, # 3rd-party profile UI
             ViewA[BasicResource][r,env]]}}
    else # no WebID found, link to onboarding-UI
      {_: :h2, c: {_: :a, c: 'Sign In', href: 'http://linkeddata.github.io/signup/'}}
    end}

  def aclURI
    if basename.index('.acl') == 0
      self
    elsif hierPart == '/'
      child '.acl'
    else
      dir.child '.acl.' + basename
    end
  end

  def allowRead
    true
  end

  def GET
    ldp
    if file? && !q.has_key?('data')
      fileGET
    elsif justPath.file?
      justPath.fileGET
    else
      stripDoc.resourceGET
    end
  end

  def fileGET
    @r[:Response].
      update({ 'Content-Type' => mime + '; charset=UTF-8',
               'ETag' => [m,size].h })
    @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
    condResponse ->{ self }
  end

  def resourceGET
    bases = [host, ""] # host, path
    paths = justPath.cascade.map(&:to_s).map &:downcase
    bases.map{|b|
      paths.map{|p| # bubble up to root
        GET[b + p].do{|fn| # bind
          fn[self].do{|r| # call
        return r }}}} # found handler, terminate search
    response
  end

  def response

    if directory?
      if uri[-1] == '/'
        @r[:container] = true
      else
        qs = @r['QUERY_STRING']
        @r[:Response].update({'Location' => uri + '/' + (qs && !qs.empty? && ('?' + qs) || '')})
        return [301, @r[:Response], []]
      end
    end

    set = []
    graph = {}

    rs = ResourceSet[q['set']]
    fs = FileSet[q['set']]
    rs[self].do{|l|l.map{|r|set.concat r.fileResources}} if rs
    fs[self].do{|files|set.concat files} if fs
    FileSet[Resource][self].do{|f|set.concat f} unless rs||fs

    return notfound if set.empty?

    env[:Response].
      update({'Content-Type' => format,
              'Link' => env[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join,
              'ETag' => [set.sort.map{|r|[r,r.m]}, format].h})

    condResponse ->{ # lazy finish of body. unused on HEAD and cache hit
      if set.size==1 && format == set[0].mime # one file in set & MIME match
        set[0] # file response
      else
        loadGraph = -> {
          set.map{|r|r.nodeToGraph graph} # load resources
          @r[:filters].push Container if @r[:container] # container-summarize
          @r[:filters].push Title
          @r[:filters].justArray.map{|f|
            Filter[f][graph,self]} # arbitrary transform
          graph }

        if NonRDF.member? format
          Render[format][loadGraph[],self]
        else
          base = @r.R.join uri
          if @r[:container] # container
            g = loadGraph[].toRDF
          else # doc
            g = RDF::Graph.new
            set.map{|f|f.justRDF.do{|doc|g.load doc.pathPOSIX, :base_uri => base}}
          end
          g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => base, :standard_prefixes => true,:prefixes => Prefixes
        end
      end}
  end

  def condResponse body
    etags = @r['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
    if etags && (etags.include? @r[:Response]['ETag'])
      [304, {}, []]
    else
      body = body.call
      @r[:Status] ||= 200
      @r[:Response]['Content-Length'] ||= body.size.to_s
      if body.class == R
        (Rack::File.new nil).serving((Rack::Request.new @r),body.pathPOSIX).do{|s,h,b|
          [s, h.update(@r[:Response]), b]}
      else
        [@r[:Status], @r[:Response], [body]]
      end
    end
  end

  def readFile parseJSON=false
    if f
      if parseJSON
        JSON.parse File.open(pathPOSIX).read
      else
        File.open(pathPOSIX).read
      end
    else
      nil
    end
  rescue
    nil
  end
  alias_method :r, :readFile

  def PUT
    return [403,{},[]] unless allowWrite
    ext = MIME.invert[@r['CONTENT_TYPE'].split(';')[0]].to_s
    versions = docroot.child '.v' # container for states
    versions.mk
    doc = versions.child Time.now.iso8601.gsub(/\W/,'') + '.' + ext 
    doc.w @r['rack.input'].read
    main = stripDoc.a('.' + ext)
    main.delete if main.e # unlink prior
    doc.ln main           # link current
    ldp
    [201,@r[:Response].update({Location: uri}),[]]
  end

  def DELETE
    return [403, {}, ["Forbidden"]] unless allowWrite
    return [409, {}, ["resource not found"]] unless exist?
    puts "DELETE #{uri}"
    delete
    [200,{
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

  def delete; node.deleteNode if e; self end

  def appendFile line
    dir.mk
    File.open(pathPOSIX,'a'){|f|f.write line + "\n"}
  end

  def writeFile o,s=false
    dir.mk
    File.open(pathPOSIX,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  end
  alias_method :w, :writeFile

  def mkdir
    e || FileUtils.mkdir_p(pathPOSIX)
    self
  end
  alias_method :mk, :mkdir

  def ln t, y=:link
    t = t.R.stripSlash
    unless t.e || t.symlink?
      t.dir.mk
      FileUtils.send y, node, t.node
    end
  end

  def ln_s t; ln t, :symlink end

  def PATCH
    update
  end

  def POST
    return [403,{},[]] unless allowWrite
    mime = @r['CONTENT_TYPE']
    case mime
#    when /^multipart\/form-data/
#      upload
    when /^application\/sparql-update/
      update
    when /^text\/turtle/
      if @r.linkHeader['type'] == Container
        path = child(@r['HTTP_SLUG'] || rand.to_s.h[0..6]).setEnv(@r)
        path.PUT
        if path.e
          [200,@r[:Response].update({Location: path.uri}),[]]
        else
          mk
        end
      else
        self.PUT
      end
    else
      [406,{'Accept-Post' => 'text/turtle'},[]]
    end
  end

  def upload
    p = (Rack::Request.new env).params
    if file = p['file']
      FileUtils.cp file[:tempfile], child(file[:filename]).pathPOSIX
      file[:tempfile].unlink
      ldp
      [201,@r[:Response].update({Location: uri}),[]]
    end
  end

  def update
    puts "PATCH #{uri}"
    query = @r['rack.input'].read
    puts query
    doc = ttl
    puts "doc #{doc}"
    model = RDF::Repository.new
    model.load doc.pathPOSIX, :base_uri => uri if doc.e
    sse = SPARQL.parse(query, update: true)
    sse.execute(model)
    doc.w model.dump(:ttl)
    ldp
    [200,@r[:Response],[]]
  end

  def allowWrite
    @r.signedIn
  end

  def accept
    @accept ||= acceptParse
  end

  def acceptParse k=''
    d={}
    env['HTTP_ACCEPT'+k].do{|k|
      (k.split /,/).map{|e| # each pair
        f,q = e.split /;/   # split MIME from q value
        i = q && q.split(/=/)[1].to_f || 1.0 # q || default
        d[i] ||= []; d[i].push f.strip}} # append
    d
  end

  def linkHeader
    lh = {}
    env['HTTP_LINK'].do{|links|
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

  def user_id
    @user ||= (user_cert || user_DNS)
  end

  def signedIn
    @signedIn ||= user.uri.match /^http/
  end

  def user_cert
    x509cert.do{|c|
      cert = R['/cache/uid/' + R.dive(c.h)] # cert URI
      verifyWebID.do{|id| cert.w id } unless cert.exist? # update cache
      return R[cert.r] if cert.exist?} # validated user-URI
  end

  def verifyWebID pem = x509cert
    if pem
      OpenSSL::X509::Certificate.new(pem).do{|x509|
        x509.extensions.find{|x|x.oid == 'subjectAltName'}.do{|user|
          user = user.value.sub /^URI./, ''
          head = {'Accept' => 'text/turtle, application/ld+json;q=0.8, text/html;q=0.5, application/xhtml+xml;q=0.5, application/rdf+xml;q=0.3'}
          graph = RDF::Repository.load user, headers: head
          query = "PREFIX : <http://www.w3.org/ns/auth/cert#> SELECT ?m ?e WHERE { <#{user}> :key [ :modulus ?m; :exponent ?e; ] . }"
          SPARQL.execute query, graph do |result|
            if x509.public_key.n.to_i == result[:m].value.to_i(16)
              user.R.ttl.w graph.dump(:ttl) # cache user-info
              return user
            else
              puts "modulus mismatch for #{user}"
            end
          end}}
    end
    nil
  end

  def x509cert
    env['rack.peer_cert'].do{|v|
      p = v.split /[\s\n]/
      return [p[0..1].join(' '),
              p[2..-3],
              p[-2..-1].join(' ')].join "\n" unless p.size < 5 }
    nil
  end

  def selector
    @idCount ||= 0
    'O' + (@idCount += 1).to_s
  end

  def user_DNS
    addr = env['HTTP_ORIGIN_ADDR'] || env['REMOTE_ADDR'] || '0.0.0.0'
    R['dns:' + addr]
  end

  def SSLupgrade; [301,{'Location' => "https://" + host + env['REQUEST_URI']},[]] end

  def q # memoize key/vals
    @q ||=
      (if q = env['QUERY_STRING']
         R.parseQS q
       else
         {}
       end)
  end

  def format # memoized MIME
    @format ||= selectFormat
  end

  Prefer = { # tiebreaker order (lowest wins)
    'text/html' => 0, 'text/turtle' => 1}

  def selectFormat

    # request by adding a URL suffix
    { '.html' => 'text/html',
      '.json' => 'application/json',
      '.ttl' => 'text/turtle',
    }[File.extname(env['REQUEST_PATH'])].do{|mime| return mime}

    # Accept parameter in request header
    accept.sort.reverse.map{|q,mimes| # MIMES in descending q-order
      mimes.sort_by{|m|Prefer[m]||2}.map{|mime| # apply tiebreakers
        return mime if R::Render[mime]||RDF::Writer.for(:content_type => mime)}}

    'text/html'
  end

  end



class Hash
  def qs # serialize to query-string
    '?'+map{|k,v|
      k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')
    }.intersperse("&").join('')
  end
end


class Pathname

  def deleteNode
    FileUtils.send (file?||symlink?) ? :rm : :rmdir, self
    parent.deleteNode if parent.c.empty? # parent now empty, delete it
  end

end
