class WebResource
  module POSIX

    # FIND(1)
    def find p
      (p && !p.empty?) ? `find #{sh} -ipath #{('*'+p+'*').sh} | head -n 2048`.lines.map{|pth|POSIX.path pth.chomp} : []
    end

    # GLOB(7)
    def glob; (Pathname.glob localPath).map &:R end

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

    # look for app in FDroid store. if not there it's probably closed-source
    Host['play.google.com'] = -> re {
      [302,{'Location' => "https://f-droid.org/en/packages/#{re.q['id']}/"},[]]}

    Host['google.com'] = Host['www.google.com'] = -> re {
      product = re.parts[0]
      case product
      when 'maps'
        Host['maps.google.com'][re]
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

    Host['maps.google.com'] = -> re {
      loc = if ll = re.path.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
              lat = ll[1]
              lng = ll[2]
              "https://tools.wmflabs.org/geohack/geohack.php?params=#{lat};#{lng}"
            elsif re.q.has_key? 'q'
              "https://www.openstreetmap.org/search?query=#{URI.escape re.q['q']}"
            else
              'https://www.openstreetmap.org/'
            end
      [302,{'Location' => loc},[]]}

  end
end
