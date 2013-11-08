watch __FILE__
require 'benchmark'

class E

  Slow ||= {}
  Errors ||= {}
  F['log']=->c,e,x=nil{ # response code, environment, extra stuff
    uri = ['http://', e['SERVER_NAME'], e['REQUEST_URI']].join
    if 500 == c
      Errors[uri] ||= {}
      Errors[uri][:time] = Time.now
    end
    if x && x.class==Float && x > 1
      s = Slow[uri] ||= {}
      s[:time] ||= 0
      s[:time] += x
      s[:last] = Time.now
      if Slow.size > 10e3
        Slow = {}
      end
    end
    $stdout.puts [e.fn,c,uri,e['HTTP_USER_AGENT'],e['HTTP_REFERER'],x].join ' '}

  F['/health/GET'] = ->e,r{
    (H [{_: :h1,
          c: {_: :a, href: '/', style: "background-color:"+E.cs, c: '/'}},
        {c: [{_: :b, c: r['SERVER_NAME']},' disk ',`df --output=pcent /|tail -n 1`]},
        {_: :a, href: '/slow', c: 'slow queries'},
        {_: :A, href: '/500', c: 'broken requests'},
        H.css('/css/health')
       ]).hR}

  F['/slow/GET'] = ->e,r{H([Slow.sort_by{|u,r|r[:time]}.reverse.html,H.css('/css/500')]).hR}

end
