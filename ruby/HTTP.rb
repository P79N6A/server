# coding: utf-8

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

  AllowMethods = %w{HEAD GET POST}
  Allow = AllowMethods.join ', '

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

  def R.call e
    return [405,{'Allow' => Allow},[]] unless AllowMethods.member? e['REQUEST_METHOD']
    return [400,{},[]] if e['REQUEST_PATH'].match(/\.php$/i)
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
    # continue call on actual resource
    resource.setEnv(e).send(e['REQUEST_METHOD']).do{|s,h,b|
      puts [resource.uri, h['Location'] ? ['->',h['Location']] : nil, resource.format, e['HTTP_REFERER'], e['HTTP_USER_AGENT']].
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
    [404,{'Content-Type' => format},[Render[format].do{|fn|fn[graph,self]} || graph.toRDF(self).dump(RDF::Writer.for(:content_type => format).to_sym, :prefixes => Prefixes)]]
  end

  def aclURI
    if basename.index('.acl') == 0
      self
    elsif hierPart == '/'
      child '.acl'
    else
      dir.child '.acl.' + basename
    end
  end

  def GET
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
    containerURI = uri[-1] == '/'
    if directory? && !containerURI
      qs = @r['QUERY_STRING']
      @r[:Response].update({'Location' => uri + '/' + (qs && !qs.empty? && ('?' + qs) || '')})
      return [301, @r[:Response], []]
    end
    q['set'] ||= (path=='/'||path.match(/^\/search/)) ? 'groonga' : 'grep' if q.has_key?('q')
    setF = q['set']
    set = []
    rs = ResourceSet[setF]
    fs = FileSet[setF]
    rs[self].do{|l|l.map{|r|set.concat r.fileResources}} if rs
    fs[self].do{|files|set.concat files} if fs
    FileSet[Resource][self].do{|f|set.concat f} unless rs||fs
    return notfound if set.empty?
    env[:Response].
      update({'Content-Type' => format,
              'Link' => env[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join,
              'ETag' => [set.sort.map{|r|[r,r.m]}, format].h})
    condResponse ->{ # lazy-body lambda. uncalled on HEAD and cache-hit
      if set.size==1 && format == set[0].mime # one file in set and MIME matches?
        set[0] # return static-file
      else
        loadGraph = -> {
          graph = {}
          set.map{|r|r.nodeToGraph graph}
          unless q.has_key? 'full'
            Summarize[graph,self] if containerURI || q.has_key?('abbr')
            Grep[graph,self] if setF == 'grep'
          end
          graph }
        if NonRDF.member? format
          Render[format][loadGraph[],self]
        else
          base = @r.R.join uri
          if containerURI
            g = loadGraph[].toRDF
          else
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

  def selector
    @idCount ||= 0
    'O' + (@idCount += 1).to_s
  end

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

  def selectFormat
    # explicit URI suffix
    { '.html' => 'text/html', '.json' => 'application/json', '.ttl' => 'text/turtle',
    }[File.extname(env['REQUEST_PATH'])].do{|m|return m}
    # environment (request header-fields)
    accept.sort.reverse.map{|q,mimes| # highest Qval bound first
      # if multiple MIMEs remain, tiebreak
      mimes.sort_by{|m|{'text/html' => 0, 'text/turtle' => 1}[m]||2}.map{|mime|
        return mime if R::Render[mime]||RDF::Writer.for(:content_type => mime)}} # native or RDF-library renderer exists
    'text/html' # default
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
