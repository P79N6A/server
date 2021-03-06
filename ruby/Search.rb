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
      when 2 # two terms
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -il #{args[1].sh}"
      when 3 # three terms
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -il #{args[2].sh}"
      when 4 # four terms
        cmd = "grep -rilZ #{args[0].sh} #{sh} | xargs -0 grep -ilZ #{args[1].sh} | xargs -0 grep -ilZ #{args[2].sh} | xargs -0 grep -il #{args[3].sh}"
      else # N terms in sequential order of appearance in match in one process invocation (if anyone reaches this, maybe theyre pasting in a sentence in which case the args are ordered)
        pattern = args.join '.*'
        cmd = "grep -ril #{pattern.sh} #{sh}"
      end
      `#{cmd} | head -n 1024`.lines.map{|path| POSIX.path path.chomp}
    end

  end
  module HTTP

    Receive['/graphql'] = Receive['/graphql/v2'] = -> r {
      r.env.map{|k,v|puts "#{k}\t #{v}"}
      [202,{},[]]
    }

  end
  module HTML
    def htmlGrep graph, q
      wordIndex = {}
      # tokenize
      args = POSIX.splitArgs q
      args.each_with_index{|arg,i| wordIndex[arg] = i }
      # highlight any matches via OR pattern
      pattern = /(#{args.join '|'})/i

      # find matches
      graph.map{|k,v|
        graph.delete k unless (k.match pattern) || (v.to_s.match pattern)}

      # highlighted matches in Abstract field
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
