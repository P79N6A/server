#watch __FILE__
class E

  # histogram
  # ?view=h&a=dc:date
  fn 'view/h',->d,e{
    a=e.q['a'].do{|e|e.expand}
    !a && 'attribute required' || (
    n=e.q['bins']&&e.q['bins'].to_f.max(999.0).min(2)||42.0
    v=F['view/'+(e&&e.q['v']||'tab')]
    (Fn 'u/hist',d,a,n).do{|h|
      [H.css('/css/hist'),
       H.js('/js/hist'),
       (Fn 'view/hist',h),
       h.map{|b,r|{style: 'display:none',
           :class => 's'+b.to_s.sub(/\./,'_'),
           c: v.(r,e)}}]})}

  # hist :: Graph, property, numBins  -> {bin -> Graph}
  fn 'u/hist',->m,p,nb=32.0{h={};bw=0;max=0;min=0
    m.map{|u,r|
      r[p]
    }.flatten.do{|v|
      v=v.compact.map{|v|v.to_time.to_f}# values
      bw = (v.max - v.min) / nb.min(1)} # bin width 
    m.map{|u,r|
      r[p].do{|v|v.each{|v|
          b=(v.to_time.to_f/bw).floor*bw # bin selector
          h[b]||={};h[b][u]=r}}} # append
    h}

  # histTable :: hist -> htmlTable
  fn 'view/hist',->h{
    scale = 255 / h.map{|b,r|r.keys.size}.max.to_f
    b=h.keys.sort
    span=(b.size / 8).min 1
    i=-1
    '<table cellspacing=0 style="width:100%;max-width:100%"><tr class=histLegend>'+
    H(b.select{|b|
        i = i + 1
        i % span == 0
      }.map{|b|
        {_: :td,
          :class => :histLegendPt,
          colspan: span,
          c: {_: :span, :class => :histLabel, c: b > 1 ? b.to_i : b}}})+
    '</tr><tr class=hist>'+
    H(b.map{|b|{_: :td, title:b.to_s.sub(/\./,'_'),style: 'background-color:#'+
          ('%02x' % (255-(h[b].do{|p|
                            p.keys.size * scale
                          }||0))).do{|x|
            'ff'+x+x}}})+
    '</tr></table>'}

end
