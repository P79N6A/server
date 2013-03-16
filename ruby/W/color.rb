#watch __FILE__
class E

  def E.c; '#%06x' % rand(16777216)end

  fn 'view/color',->d,e{

    n = (e.q['n']||42).to_i.max 255
    
    hsv2rgb=->h,s,v{
      i = h.floor
      f = h - i
      p = v * (1 - s)
      q = v * (1 - (s * f))
      t = v * (1 - (s * (1 - f)))    
      r,g,b=[[v,t,p],
             [q,v,p],
             [p,v,t],
             [p,q,v],
             [t,p,v],
             [v,p,q]][i].map{|q|q*255.0}}

    [H.css('/css/color'),
     {style: 'display:table;width:100%',
         c: [(1..10).map{|s| {class: :row, c: (0..n-1).map{|h| {class: :c,style: 'background-color:#%02x%02x%02x' % hsv2rgb.(h/(n/6.0),s/10.0,1.0)}}}},
(1..10).to_a.reverse.map{|v| {class: :row, c: (0..n-1).map{|h| {class: :c,style: 'background-color:#%02x%02x%02x' % hsv2rgb.(h/(n/6.0),1.0,v/10.0)}}}}]}]}

end
