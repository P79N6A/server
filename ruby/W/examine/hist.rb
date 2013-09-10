#watch __FILE__
class E

  # histogram
  fn 'view/histogram',->d,e{

    # a :: attribute to chart
    a = e.q['a'].do{|e|e.expand}

    !a && 'attribute required' ||
    (# bins :: number of buckets
     n = e.q['bins'] && e.q['bins'].to_f.max(999.0).min(1) || 64.0

     # hv :: bin template 
     v = F['view/'+(e&&e.q['hv']||'tab')]

     # construct histogram bins
     (Fn 'view/histogram/bins',d,a,n).do{|h,m|

       [H.css('/css/hist'),%w{mu hist}.map{|s|H.js('/js/'+s)},
        (Fn 'view/histogram/render',h),
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
                 # bin children view
                 v.(r,e)]})}]})}

  F['view/h']=F['view/histogram']

  # Graph, property, numBins  -> {bin -> Graph}
  fn 'view/histogram/bins',->m,p,nb{
    h = {}
    bw = 0
    min = 0
    max = 0
    m.map{|u,r|
      # attribute accessor
      r[p]
    }.flatten.do{|v|
      # values
      v = v.compact.map{|v|v.to_time.to_f}
      max = v.max
      min = v.min
      # bin-width
      bw = (max - min) / nb}

    # construct bins
    (0..nb-1).map{|b|h[b] = {}}

    # each resource
    m.map{|u,r|

      # binnable properties
      r[p].do{|v|
        v.each{|v|
          # bin selector
          b = ((v.to_time.to_f - min) / bw).floor

          # append to bin
          h[b][u] = r }}}

    # histogram model
    [h, {min: min, max: max, bw: bw}] }

  fn 'view/histogram/render',->h{
    scale = 255 / h.map{|b,r|r.keys.size}.max.to_f
    b = h.keys.sort
    ['<table class=histogram><tr>',
     b.map{|b|
       {_: :td, class: 'b'+b.to_s, style: 'background-color:#'+('%02x' % (255-h[b].keys.size*scale)).do{|x|'ff'+x+x}}},
     '</tr></table>']}

end
