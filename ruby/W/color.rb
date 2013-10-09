#watch __FILE__
class E

  def E.c; '#%06x' % rand(16777216) end
  def E.cs; '#%02x%02x%02x' % F['color/hsv2rgb'][rand*6,1,1] end

  fn 'color/hsv2rgb',->h,s,v{
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

end
