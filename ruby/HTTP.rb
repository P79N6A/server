# coding: utf-8
class WebResource
  module HTTP
    include URIs

    # Rack entry-point
    def self.call env
      return [405,{},[]] unless %w{HEAD GET}.member? env['REQUEST_METHOD']
      rawpath = env['REQUEST_PATH'].utf8.gsub /[\/]+/, '/'
      path = Pathname.new(rawpath).expand_path.to_s        # evaluate path
      path += '/' if path[-1] != '/' && rawpath[-1] == '/' # preserve trailing-slash
      env['q'] = parseQs env['QUERY_STRING']
      path.R.environment(env).send env['REQUEST_METHOD']
    rescue Exception => x
      [500,{'Content-Type'=>'text/plain'},[[x.class,x.message,x.backtrace].join("\n")]]
    end

    def self.parseQs qs
      if qs
        h = {}
        qs.split(/&/).map{|e|
          k, v = e.split(/=/,2).map{|x|CGI.unescape x}
          h[(k||'').downcase] = v}
        h
      else
        {}
      end
    end

    def environment env = nil
      if env
        @r = env
        self
      else
        @r
      end
    end

    def HEAD; self.GET.do{|s,h,b|[s,h,[]]} end

    def GET
      @r[:Response] = {}
      @r[:Links] = {}
      parts = path[1..-1].split '/'
      firstPart = parts[0] || ''
      return fileResponse if node.file?
      return (chronoDir parts) if firstPart.match(/^(y(ear)?|m(onth)?|d(ay)?|h(our)?)$/i)
      return [302,{'Location' => path+'/'+qs},[]] if node.directory? && path[-1] != '/'

      # datedir pointers
      dp = []
      dp.push parts.shift.to_i while parts[0] && parts[0].match(/^[0-9]+$/)
      n = nil; p = nil
      case dp.length
      when 1 # Y
        year = dp[0]
        n = '/' + (year + 1).to_s
        p = '/' + (year - 1).to_s
      when 2 # Y-m
        year = dp[0]
        m = dp[1]
        n = m >= 12 ? "/#{year + 1}/#{01}" : "/#{year}/#{'%02d' % (m + 1)}"
        p = m <=  1 ? "/#{year - 1}/#{12}" : "/#{year}/#{'%02d' % (m - 1)}"
      when 3 # Y-m-d
        day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue nil
        if day
          p = (day-1).strftime('/%Y/%m/%d')
          n = (day+1).strftime('/%Y/%m/%d')
        end
      when 4 # Y-m-d-H
        day = ::Date.parse "#{dp[0]}-#{dp[1]}-#{dp[2]}" rescue nil
        if day
          hour = dp[3]
          p = hour <=  0 ? (day - 1).strftime('/%Y/%m/%d/23') : (day.strftime('/%Y/%m/%d/')+('%02d' % (hour-1)))
          n = hour >= 23 ? (day + 1).strftime('/%Y/%m/%d/00') : (day.strftime('/%Y/%m/%d/')+('%02d' % (hour+1)))
        end
      end
      sl = parts.empty? ? '' : (path[-1] == '/' ? '/' : '') # trailing slash
      @r[:Links][:prev] = p + '/' + parts.join('/') + sl + qs + '#prev' if p && R[p].e
      @r[:Links][:next] = n + '/' + parts.join('/') + sl + qs + '#next' if n && R[n].e
      @r[:Links][:up] = dirname + (dirname == '/' ? '' : '/') + qs + '#r' + path.sha2 unless path=='/'

      # inline-expansion pointer
      if q.has_key? 'head'
        qq = q.dup; qq.delete 'head'
        @r[:Links][:down] = path + (HTTP.qs qq)
      end

      # resource set
      set = selectNodes
      return notfound if !set || set.empty?
      format = selectMIME

      # response header
      @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format,
                            'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha2})

      # conditional response
      entity @r, ->{
        if set.size == 1 && set[0].mime == format
          set[0] # static file good to go
        else # transcode and/or merge sources
          if format == 'text/html'
            htmlDocument load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF
            g = RDF::Graph.new
            set.map{|n| g.load n.toRDF.localPath, :base_uri => n.stripDoc }
            g.dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
          end
        end}
    end

    # file(s) -> graph-in-tree
    def load set
      graph = RDF::Graph.new # graph
      g = {}                 # tree
      rdf,json = set.partition &:isRDF
      # RDF
      rdf.map{|n|
        graph.load n.localPath, :base_uri => n}
      graph.each_triple{|s,p,o| # each triple
        s = s.to_s; p = p.to_s # subject, predicate
        o = [RDF::Node, RDF::URI, WebResource].member?(o.class) ? o.R : o.value # object
        g[s] ||= {'uri'=>s}
        g[s][p] ||= []
        g[s][p].push o unless g[s][p].member? o} # insert
      # JSON
      json.map{|n|
        n.transcode.do{|transcode|
          ::JSON.parse(transcode.readFile).map{|s,re| # subject
            re.map{|p,o| # predicate object(s)
              o.justArray.map{|o| # each triple
                o = o.R if o.class==Hash
                g[s] ||= {'uri'=>s}
                g[s][p] ||= []
                g[s][p].push o unless g[s][p].member? o} unless p == 'uri' }}}} # insert

      # set metadata
      if q.has_key?('du') && path != '/'
        set.select{|d|d.node.directory?}.-([self]).map{|node|
          g[node.path+'/']||={}
          g[node.path+'/'][Size] = node.du}
      elsif q.has_key?('f') || q.has_key?('q') || @r[:glob]
        set.map{|r|
          bin = r.dirname + '/'
          g[bin] ||= {'uri' => bin}
          g[bin][Size] = 0 if !g[bin][Size] || g[bin][Size].class==Array
          g[bin][Size] += 1}
      end
      g
    end

    def chronoDir ps
      time = Time.now
      loc = time.strftime(case ps[0][0].downcase
                          when 'y'
                            '%Y'
                          when 'm'
                            '%Y/%m'
                          when 'd'
                            '%Y/%m/%d'
                          when 'h'
                            '%Y/%m/%d/%H'
                          else
                          end)
      [303,@r[:Response].update({'Location' => '/' + loc + '/' + ps[1..-1].join('/') + qs}),[]]
    end

    def fileResponse
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(mime) ? (mime+'; charset=utf-8') : mime,
                            'ETag' => [m,size].join.sha2})
      @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
      if q.has_key?('preview') && ext.match(/(mp4|mkv|png|jpg)/i)
        filePreview
      else
        entity @r
      end
    end

    def entity env, body = nil
      etags = env['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
      if etags && (etags.include? env[:Response]['ETag'])
        [304, {}, []]
      else
        body = body ? body.call : self
        if body.class == WebResource # use Rack handler for static resource
          (Rack::File.new nil).serving((Rack::Request.new env),body.localPath).do{|s,h,b|
            [s,h.update(env[:Response]),b]}
        else
          [(env[:Status]||200), env[:Response], [body]]
        end
      end
    end

    def notfound; [404,{'Content-Type' => 'text/html'},[htmlDocument]] end

    # querystring -> Hash
    def q fromEnv = true
      fromEnv ? @r['q'] : HTTP.parseQs(query)
    end

    def inDoc; path == @r['REQUEST_PATH'] end

    # env -> ?querystring
    def qs; @r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?'+@r['QUERY_STRING']) || '' end

    # Hash -> ?querystring
    def HTTP.qs h; '?'+h.map{|k,v|k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('') end

  end
  include HTTP
end
