#watch __FILE__
require 'benchmark'

class E
  Slow ||= {}
  Errors ||= {}

  F['/health/GET'] = ->e,r{
    (H [{_: :h1,
          c: {_: :a, href: Site, style: "background-color:"+E.cs, c: '/'}},
        {c: [{_: :b, c: Host[7..-1]},`uptime`,'disk ',`df --output=pcent /|tail -n 1`]},
        {_: :a, href: Site+'/slow', c: 'slow queries'},
        {_: :A, href: Site+'/500', c: 'broken requests'},
        H.css('/host')
       ]).hR}

  F['/slow/GET'] = ->e,r{H([Slow.sort_by{|u,r|r[:time]}.reverse.html,H.css('/css/500')]).hR}

end
