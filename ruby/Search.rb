class WebResource
  module POSIX

    # WebResource -> file(s)
    def selectNodes
      (if directory?
       if q.has_key?('f') && path!='/' # FIND
         found = find q['f']
         found
       elsif q.has_key?('q') && path!='/' # GREP
         grep q['q']
       else # LS
         if uri[-1] == '/'
           index = (self+'index.html').glob
           if !index.empty? && qs.empty? # static index
             index
           else
             [self, children]
           end
         else # outside container
           @r[:links][:down] = path + '/' + qs
           self
         end
       end
      else # GLOB, parametric or default of baseURI+ext(s)
        [self, ((match /[\*\{\[]/) ? self : (self + '.*')).glob ]
       end).justArray.flatten.compact.uniq.select &:exist?
    end

    # grepPattern -> file(s)
    def grep q
      args = POSIX.splitArgs q
      case args.size
      when 0
        return []
      when 2
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -il #{args[1].sh}"
      when 3
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -il #{args[2].sh}"
      when 4
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -ilZ #{args[2].sh} | xargs -0 grep -il #{args[3].sh}"
      else
        pattern = args.join '.*'
        cmd = "grep -ril #{pattern.sh} #{sh}"
      end
      `#{cmd} | head -n 1024`.lines.map{|path| POSIX.path path.chomp}
    end

  end
  module HTTP

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
    
    Host['www.google.com'] = -> re {
      product = re.parts[0]
      case product
      when 'maps'
        loc = if ll = re.path.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
                lat = ll[1]
                lng = ll[2]
                "https://tools.wmflabs.org/geohack/geohack.php?params=#{lat};#{lng}"
              elsif re.q.has_key? 'q'
                "https://www.openstreetmap.org/search?query=#{URI.escape re.q['q']}"
              else
                'https://www.openstreetmap.org/'
              end
        [302,{'Location' => loc},[]]
      when 'search'
        loc = if re.q.has_key? 'q'
                "https://duckduckgo.com/?q=#{URI.escape re.q['q']}"
              else
                'https://duckduckgo.com'
              end
        [302,{'Location' => loc},[]]
      else
        [404,{},[]]
      end}

  end
end
