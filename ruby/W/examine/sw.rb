#watch __FILE__

# databases of HF frequencies
# curl http://eibispace.de/dx/sked-b11.csv > s.ssv
# wget http://www1.m2.mediacat.ne.jp/binews/bib11.zip http://hfcc.org/data/b11/b11allx2.zip
# unzip *zip

class E

  F["?"]||={}
  F["?"].update({
                  'sw' => {
                    'view' => 'examine',
                    'ev'=>'sw',
                    'a'=>'Lng:49',
                    'minP' => 'FREQ',
                    'maxP' => 'FREQ',
                    'filter' => 'map',
                    'kHz:75' => 'FREQ',
                    'Time(UTC):93' => 'UTC',
                    'Station:201' => 'STATION',
                  }
                })

  fn 'view/sw/base',->d,e,c{
    bands = {
      120 => [2200,2500],
      90 => [3100,3450],
      75 => [3890,4123],
      60 => [4740,5125],
      49 => [800,6300],
      40 => [7200,7600],
      31 => [9200,9999],
      25 => [11500,12160],
      22 => [13500,13900],
      19 => [15001,15900],
      16 => [17500,17900],
      13 => [21450,21850],
      11 => [25700,26500],
    }
    band=0
    e[:clr]={}
    e[:fmax]=d.map{|_,r|r['FREQ'][0].to_f}.flatten.max||30000.0
    e[:scale]=100/(e[:fmax] - (d.map{|_,r|r['FREQ'][0].to_f}.flatten.min||0))
    [(H.css '/css/sw'),(H.js '/js/mu'),(H.js '/js/sw'),
     {id: :bands,
       c: bands.map{|meters,bounds|
         band += 1
         {_: :a, class: :band,
           style: "background-color:##{band % 2 == 0 ? 'fff' : 'cecece'}",
           c: '<span style="font-size:1.4em">'+meters.to_s+'</span>m',
           href: meters.to_s+'m.html'}}},
       {id: :scales, c: %w{800 1200 1600}.map{|b|{_: :span,class: :scale, c: b}}},
       {id: :spectrum, style: 'height:800px;position:absolute', c:
         [{id: 't'},{class: 'loc'},{id: 'clock'},c.(),
          (0..23).map{|h|
            [0,15,30,45].map{|m|
              t = h*60+m
              left = t*4
              utc="%02d%02d"%[h,m]
              [(1..3).map{|l|
                 {_: :span, class: :u, c: utc, style: "top:#{l*25}%;left:#{left-19}px;"}},
                 {class: :s,style: "border-color:#{m==0 ? 'white' : '#666'};left:#{left}px;"}]}}]}]}
  
  fn 'view/sw/item',->r,x{
    min=->t{t='%04d' % (t.class==String && t.empty? ? 0 : t)
      t[0..1].to_i*60+t[2..3].to_i}
    u = r['UTC'][0].to_s.match(/(\d+)-?(\d+)?/)
    b = u[1].to_i.max 2359
    e = (u[2] ? u[2].to_i : b + 30).max 2359
    f = r['FREQ'][0].to_f
    fi = f.to_i
    n = fi / 100
    x[:clr][n] ||= '#%06x' % rand(16777216)
    f && b && e &&
    (bmin=min.(b); emin=min.(e)
     top=(x[:fmax]-f)*x[:scale]
     v=->b,e{
       {t: r.except('uri','UTC','FREQ').values.join(' '),:class => :bar, b: b, e: e, f: fi,style:"
background-color:#{x[:clr][n]};
top: #{top}%;
left: #{b*4.0}px;
width:#{(e-b) * 4.0}px;
",c: (e-b > 60 ?
      ((0..(e-b)/60).map{|h|
         {_: :span, style: "position:absolute;left:#{h*120}px;top:0",c: f}}) : f)}}
     (bmin > emin) ? [v.(0,emin),
                      v.(bmin,1440)] : v.(bmin,emin))}
  
  fn 'view/sw',->d,e{
    i=F['view/sw/item']
    Fn 'view/sw/base',d,e,->{d.map{|u,r|i.(r,e)}}}

  fn 'filter/gh',->o,m,_{
    m.values.map{|r|
      r[Content].do{|c| 
        c.join.lines.each_with_index{|l,i|
          l.match(/^[^<]+$/) &&
          (u=r.uri+'#'+i.to_s
           m[u]={'uri' => u,
             'big'=>[l.scan(/\b[A-Z][A-Z][A-Z]+\b/)],
             Content=>[l]}
           l.scan(/\d{4,}/){|d| d=d.to_i
             if (d > 2400) && (d < 30000)
               m[u]['FREQ']=[d]
             elsif
               m[u]['UTC']=[d]
             end}
           m.delete u unless m[u].has_keys ['UTC','FREQ']
           )}
        m.delete r.uri
      }}}
  
end
