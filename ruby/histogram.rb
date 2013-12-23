#watch __FILE__
class E

  fn 'view/histogram',->m,e{
    e.q['a'].do{|a|Fn 'histogram/main',m,e} ||
    (Fn 'view/facetSelect',m,e)}

  fn 'histogram/main',->d,e{

    # a :: attribute to chart
    a = e.q['a'].do{|e|e.expand} || Date

    # bins :: number of buckets
    n = e.q['bins'].do{|b| b.to_f.max(999.0).min(1)} || 64.0
    
    # hv :: bin template 
    v = F['view/'+(e.q['hv']||'title')]

    # construct histogram bins
    (Fn 'histogram/bins',d,a,n).do{|h,m|
      
      [H.css('/css/hist'),%w{mu hist}.map{|s|H.js('/js/'+s)},
       (Fn 'histogram',h),{style: "width: 100%; height: 5em"},
       h.map{|b,r|
         # skip empty bins
         r.empty? ? ' ' :
         (x = m[:min] + m[:bw] * b
          from = a == Date ? Time.at(x).to_s : x.to_s
          to = a == Date ? Time.at(x + m[:bw]).to_s : (x + m[:bw]).to_s
          # wrap bin
          { class: 'histBin b'+b.to_s,
            c: [# label bin
                {_: :h3, c: from + ' &rarr; ' + to },
                # bin-scoped view
                v[r,e]]})}]}}

  F['view/h']=F['view/histogram']

  # Graph, property, numBins  -> {bin -> Graph}
  fn 'histogram/bins',->m,p,nb{
    h = {}; bw = 0; min = 0; max = 0
    m.map{|u,r|
      # attribute accessor
      r[p]
    }.flatten.do{|v|
      # values
      v = v.map{|v| p == Date ? v.to_time : v }.select{|v| v.respond_to? :to_f}.map &:to_f
      max = v.max || 0
      min = v.min || 0
      width = (max-min).do{|w| w.zero? ? 1 : w}
      bw = width / nb }

    # construct bins
    (0..nb).map{|b|h[b] = {}}

    # each resource
    m.map{|u,r|

      # binnable properties
      r[p].do{|v|
        v.each{|v|
          # date handling
          v = p == Date ? v.to_time : v
          if v.respond_to? :to_f
            # bin select
            b = ((v.to_f - min) / bw).floor
            # append
            h[b][u] = r
          end
        }}}

    # histogram model
    [h, {min: min, max: max, bw: bw}] }

  fn 'histogram',->h{
    scale = 255 / h.map{|b,r|r.keys.size}.max.do{|m|m.zero? ? 1 : m}.do{|m|m.respond_to?(:to_f) ? m.to_f : 1}
    bins = h.keys.sort
    ['<table class=histogram><tr>',
     bins.map{|b|
       mag = h[b].keys.size
       {_: :td, class: 'b' + b.to_s,
         style: 'background-color:#'+('%02x' % (255-mag*scale)).do{|x|'ff'+x+x}}},
     '</tr></table>']}

end
