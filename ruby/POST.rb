watch __FILE__
class E

  def POST
    type = @r['CONTENT_TYPE']
    puts [:POST,type,uri].join ' '

    case type
    when /^application\/sparql-update/
      puts :SPARQL_UDATE
      puts @r['rack.input'].read

    when /^application\/x-www-form-urlencoded/
      ch = nil
      (Rack::Request.new @r).params.map{|k,v|
        s, p, o = (CGI.unescape k).split S
        if s && p && o 
          oP = o
          begin
            s, p, o = [s, p, o].map &:unpath
            s = s.uri[0..-2].E if s.uri[-1] == '/'
            p = p.uri[0..-2].E if p.uri[-1] == '/'
            if oP.E == (E.literal v) && s.uri.match(/^http/) && p.uri.match(/^http/)
              puts "POST <#{s}> <#{p}> <#{o}>"
              s[p,o,v]
              ch = true
            end
          rescue  Exception => x
            puts x
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
