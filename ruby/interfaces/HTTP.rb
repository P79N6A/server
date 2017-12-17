# coding: utf-8
class R
  module HTTP
    def self.call env
      return [404,{},[]] if env['REQUEST_PATH'].match(/\.php$/i)
      return [405,{},[]] unless %w{HEAD GET}.member? env['REQUEST_METHOD']
      rawpath = env['REQUEST_PATH'].utf8.gsub /[\/]+/, '/' # /-collapse
      path = Pathname.new(rawpath).expand_path.to_s        # evaluate path
      path += '/' if path[-1] != '/' && rawpath[-1] == '/' # preserve trailing-slash
      path.R.send env['REQUEST_METHOD'], env
    rescue Exception => x
      [500,{'Content-Type'=>'text/plain'},[[x.class,x.message,x.backtrace].join("\n")]]
    end
    include URIs
    def HEAD env; self.GET(env).do{|s,h,b|[s,h,[]]} end
    def GET env
      @r = env
      @r[:Response] = {}
      @r[:Links] = {}
      parts = path[1..-1].split '/'
      firstPart = parts[0] || ''
      directory = node.directory?
      return file if node.file?
      return feed if parts[0] == 'feed'
      return (chrono parts) if firstPart.match(/^(y(ear)?|m(onth)?|d(ay)?|h(our)?)$/i)
      return [204,{},[]] if firstPart.match(/^gen.*204$/)
      return [302,{'Location' => path+'/'+qs},[]] if directory && path[-1]!='/' 
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
      sl = parts.empty? ? '' : (path[-1] == '/' ? '/' : '')
      @r[:Links][:prev] = p + '/' + parts.join('/') + sl + qs + '#prev' if p && R[p].e
      @r[:Links][:next] = n + '/' + parts.join('/') + sl + qs + '#next' if n && R[n].e
      @r[:Links][:up] = dirname + (dirname == '/' ? '' : '/') + qs unless path=='/'
      if q.has_key? 'head'
        qq = q.dup; qq.delete 'head'
        @r[:Links][:down] = path + (HTTP.qs qq)
      end
      set = (if directory
             if q.has_key?('f') && path!='/' # FIND
               found = find q['f']
               q['head'] = true if found.size > 127
               found
             elsif q.has_key?('q') && path!='/' # GREP
               grep q['q']
             else
               if uri[-1] == '/' # inside (trailing slash)
                 index = (self+'index.{html,ttl}').glob # static index (HTML or Turtle)
                 index.empty? ? [self, children] : index # container and its contents
               else # outside
                 @r[:Links][:down] = path + '/' + qs
                 self # just container
               end
             end
            else
              @r[:glob] = match /\*/
              (@r[:glob] ? self : (self+'.*')).glob # GLOB
             end).justArray.flatten.compact.select &:exist?

      return notfound if !set || set.empty?
      @r[:Response].update({'Link' => @r[:Links].map{|type,uri|"<#{uri}>; rel=#{type}"}.intersperse(', ').join}) unless @r[:Links].empty?
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(format) ? (format+'; charset=utf-8') : format,
                            'ETag' => [set.sort.map{|r|[r,r.m]}, format].join.sha2})

      condResponse @r, ->{ # body
        if set.size == 1 && set[0].mime == format
          set[0] # static body
        else # dynamic body
          if format == 'text/html'
            renderHTML load set
          elsif format == 'application/atom+xml'
            renderFeed load set
          else # RDF
            (loadRDF set).dump (RDF::Writer.for :content_type => format).to_sym, :base_uri => self, :standard_prefixes => true
          end
        end}
    end

    def feed; [303,@r[:Response].update({'Location'=> Time.now.strftime('/%Y/%m/%d/%H/?feed')}),[]] end

    def chrono ps
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
      [303,@r[:Response].update({'Location' => '/' + loc + '/' + ps[1..-1].join('/') + (qs.empty? ? '?head' : qs)}),[]]
    end

    def file
      @r[:Response].update({'Content-Type' => %w{text/html text/turtle}.member?(mime) ? (mime+'; charset=utf-8') : mime,
                            'ETag' => [m,size].join.sha2})
      @r[:Response].update({'Cache-Control' => 'no-transform'}) if mime.match /^(audio|image|video)/
      if q.has_key?('preview') && ext.match(/(mp4|mkv|png|jpg)/i)
        filePreview
      else
        condResponse @r
      end
    end

    def condResponse env, body=nil
      etags = env['HTTP_IF_NONE_MATCH'].do{|m| m.strip.split /\s*,\s*/ }
      if etags && (etags.include? env[:Response]['ETag'])
        [304, {}, []]
      else
        body = body ? body.call : self
        if body.class == R # file-ref
          (Rack::File.new nil).serving((Rack::Request.new env),body.localPath).do{|s,h,b|[s,h.update(env[:Response]),b]}
        else
          [(env[:Status]||200), env[:Response], [body]]
        end
      end
    end

    def notfound; [404,{'Content-Type' => 'text/html'},[renderHTML({})]] end

    # Hash -> qs
    def self.qs h; '?'+h.map{|k,v|k.to_s + '=' + (v ? (CGI.escape [*v][0].to_s) : '')}.intersperse("&").join('') end

    # request-env -> qs
    def qs; @qs ||= (@r['QUERY_STRING'] && !@r['QUERY_STRING'].empty? && ('?' + @r['QUERY_STRING']) || '') end

    # qs -> Hash
    def q
      @q ||= # memoize
        (if q = @r['QUERY_STRING']
         h = {}
         q.split(/&/).map{|e|
           k, v = e.split(/=/,2).map{|x|CGI.unescape x}
           h[(k||'').downcase] = v}
         h
        else
          {}
         end)
    end

    def format; @format ||= selectFormat end

    def selectFormat
      return 'application/atom+xml' if q.has_key?('feed')
      (d={}
       @r['HTTP_ACCEPT'].do{|k|
         (k.split /,/).map{|e| # MIME/q-val pairs
           f,q = e.split /;/   # split pair
           i = q && q.split(/=/)[1].to_f || 1.0
           d[i] ||= []; d[i].push f.strip}} # index q-val
       d).sort.reverse.map{|q,formats| # ordered index
        formats.map{|mime| #serializable?
          return mime if RDF::Writer.for(:content_type => mime) || %w{application/atom+xml text/html}.member?(mime)}}
      'text/html' # default
    end
  end
end
