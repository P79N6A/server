watch __FILE__
class E

  def POST
    type = @r['CONTENT_TYPE']
    case type
    when /^application\/sparql-update/

    when /^application\/x-www-form-urlencoded/
      puts :POST
      ch = nil
      (Rack::Request.new @r).params.map{|k,v|
        s, p, o = (CGI.unescape k).split /\/\._/
        if s && p && o 
          oP = o
          s, p, o = [s, p, o].map &:unpath
          puts "s #{s} p #{p} o #{o.class} #{o}"
          if oP.E == (E.literal v) && s.uri.match(/^http/) && p.uri.match(/^http/)
            puts "POST <#{s}> <#{p}> <#{o}>"
            s[p,o,v]
            ch = true
          end
        end}
      if ch # state changed
        g = {}
        fromStream g, :triplrFsStore
        ef.w g, true
      end
    end

    [303,{'Location'=>uri},[]]    
  end

end
