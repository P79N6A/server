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
      when 2 # two terms in any order
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -il #{args[1].sh}"
      when 3 # three terms in any order
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -il #{args[2].sh}"
      when 4 # four terms in any order
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -ilZ #{args[2].sh} | xargs -0 grep -il #{args[3].sh}"
      else # N terms in sequential order of appearance. one scan less invocations..go nuts
        pattern = args.join '.*'
        cmd = "grep -ril #{pattern.sh} #{sh}"
      end
      `#{cmd} | head -n 1024`.lines.map{|path| POSIX.path path.chomp}
    end

  end
  module HTTP

    # lookup app in FDroid store, if not there it's probably closed-source
    Host['play.google.com'] = -> re {
      [302,{'Location' => "https://f-droid.org/en/packages/#{re.q['id']}/"},[]]}

    Host['connectivitycheck.gstatic.com'] = -> re {
      [204,{'Content-Length' => 0},[]]}

    Host['google.com'] = Host['goo.gl'] = Host['www.google.com'] = -> re {
      product = re.parts[0]
      case product
      when 'gen_204'
        Host['connectivitycheck.gstatic.com'][re]
      when 'generate_204'
        Host['connectivitycheck.gstatic.com'][re]
      when 'complete' # keystroke logger
        puts 'SEARCH ' + re.q['q'].to_s
        re.notfound
      when 'maps' # goto Maps lambda
        Host['maps.google.com'][re]
      when 'search' # goto DDG
        loc = if re.q.has_key? 'q'
                "https://duckduckgo.com/?q=#{URI.escape re.q['q']}"
              else
                'https://duckduckgo.com'
              end
        [302,{'Location' => loc},[]]
      else
        re.notfound
      end}

    # redirect to open alternatives
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
  module HTML
    def htmlGrep graph, q
      wordIndex = {}
      args = POSIX.splitArgs q
      args.each_with_index{|arg,i| wordIndex[arg] = i }
      pattern = /(#{args.join '|'})/i
      # find matches
      graph.map{|u,r|
        keep = !(r.has_key?(Abstract)||r.has_key?(Content)) || r.to_s.match(pattern)
        graph.delete u unless keep}
      # highlight matches
      graph.values.map{|r|
        (r[Content]||r[Abstract]).justArray.map(&:lines).flatten.grep(pattern).do{|lines|
          r[Abstract] = lines[0..5].map{|l|
            l.gsub(/<[^>]+>/,'')[0..512].gsub(pattern){|g| # capture
              HTML.render({_: :span, class: "w#{wordIndex[g.downcase]}", c: g}) # wrap
            }} if lines.size > 0 }}
      # CSS
      graph['#abstracts'] = {Abstract => HTML.render({_: :style, c: wordIndex.values.map{|i|
                                                        ".w#{i} {background-color: #{'#%06x' % (rand 16777216)}; color: white}\n"}})}
    end
  end
end
