watch __FILE__
class E

  def POST
    puts [:POST,@r['CONTENT_TYPE']].join ' '

    case @r['CONTENT_TYPE']
    when /^application\/sparql-update/
      puts :SPARQL
      puts @r['rack.input'].read

    when /^application\/x-www-form-urlencoded/
      puts "form"
      (Rack::Request.new @r).params.map{|k,v|
        puts "POST #{uri} #{k} #{v}"
        s, p, o = (CGI.unescape k).split S
        if s && p && o
          oP = o # object path
          begin
            s,p,o = [s,p,o].map &:unpath
            s = s.uri[0..-2].E if s.uri[-1] == '/'
            p = p.uri[0..-2].E if p.uri[-1] == '/'
            unless oP.E == (E.literal v)
              puts ["POST",:s,uri,:p,p,:o,o,o.class,:oV,v,v.class].join ' '
              s[p,o,v] # edit
            end
          rescue  Exception => x
            puts x
          end
        end} if false

      # update graph snapshot
      g = {}
      fromStream g, :triplrFsStore
      ef.w g, true
    end

    [303,{'Location'=>uri},[]]    
  end

end
