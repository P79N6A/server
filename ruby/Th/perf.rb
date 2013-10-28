
watch __FILE__
require 'benchmark'

class E
  Slow ||= {}

  F['log']=->c,e,x=nil{ # response code, environment, extra stuff
    uri = ['http://', e['SERVER_NAME'], e['REQUEST_URI']].join
    if x && x.class==Float && x > 1
      s = Slow[uri] ||= {uri: uri}
      s[:time] ||= 0
      s[:time] += x
      s[:last] = Time.now
      if Slow.size > 500
        #gc
      end
    end
    $stdout.puts [e.fn,c,uri,e['HTTP_USER_AGENT'],e['HTTP_REFERER'],x].join ' '}

  F['/slow/GET'] = ->e,r{H([Slow.sort_by{|u,r|r[:time]}.reverse.html,H.css('/css/500')]).hR}

end
