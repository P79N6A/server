#watch __FILE__
class R

  def POST
    # custom handler lookup cascade
    pathSegment.do{|path|
      lambdas = path.cascade.map{|p| p.uri.t + 'POST' }
      ['http://'+@r['SERVER_NAME'],""].map{|h| lambdas.map{|p|
          F[h + p].do{|fn| fn[self,@r].do{|r|
              $stdout.puts [r[0],'http://'+@r['SERVER_NAME']+@r['REQUEST_URI'],@r['HTTP_USER_AGENT'],@r['HTTP_REFERER'],@r.format].join ' '
              return r
            }}}}}
    basicPOST
  end
  def basicPOST
#    return [303,{'Location'=>uri},[]] # comment to shutoff POST
    case @r['CONTENT_TYPE']
    when /^application\/x-www-form-urlencoded/
      changed = false
      (Rack::Request.new @r).params.map{|k,v|

        # triple ID field
        s, p, tripleA = JSON.parse CGI.unescape k
        s = s.R
       pp = s.predicatePath p

        # clean input 
        o = v.match(/\A(\/|http)[\S]+\Z/) ? v.R : F['cleanHTML'][v]

        # delta ID
        tripleB = pp.objectPath(o)[0]

        if tripleA.to_s != tripleB.to_s # changed?
          # remove triple
          tripleA && tripleA.R.do{|t| t.delete if t.e }
          # create triple
          s[p] = o unless o.class==String && o.empty?
          changed = true
        end}
      if changed
        g = {} # triples -> graph
        fromStream g, :triplrDoc
        if g.empty? # no triples left
          ef.delete
        else # write graph to doc #TODO mint docURI for version and (sym|hard)link to it
          ef.w g, true
        end
      end
    end
    # continue - back to editor
    [303,{'Location'=>uri+'?graph=edit'},[]]
  end

end
