watch __FILE__
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
     (Fn 'view/histogram/bins',d,a,n).do{|h|

       [H.css('/css/hist'),H.js('/js/hist'),(Fn 'view/histogram/content',h),
        h.map{|b,r|{style: 'display:none', class: 's'+b.to_s.sub(/\./,'_'),
            c: v.(r,e)}}]})}

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
    h }

  fn 'view/histogram/content',->h{
    scale = 255 / h.map{|b,r|r.keys.size}.max.to_f
    b = h.keys.sort
    ['<table cellspacing=0 style="width:100%;max-width:100%"><tr class=hist>',
     b.map{|b|
       {_: :td, style: 'background-color:#'+
         ('%02x' % (255 - h[b].keys.size * scale)).do{|x|
           'ff'+x+x}}},
     '</tr></table>']}

end
