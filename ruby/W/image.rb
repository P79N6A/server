#watch __FILE__
class E

  def thumb?
    mime.match(/^(image|video)/) && # is file an image?
   @r.qs.match(/^[0-9]{0,3}x[0-9]{0,3}$/) && # valid dimensions?
    base.match(/^[^.]/) # skip "invisible" images
  end

  def thumb
    E['/E/images/'+
      [no.stat.do{|s|
         [s.ino,s.mtime]},
       @r.qs].h.dive+'.png'].do{|n| n.e ||
      (n.dirname.dir
       mime.match(/^video/) &&
       `ffmpegthumbnailer -s #{@r.qs.match(/[0-9]+/).to_s} -i #{sh} -o #{n.sh}` ||
       `gm convert #{sh} -thumbnail "#{@r.qs}" #{n.sh}`)
      n.env @r }
  end
  
  fn 'view/img',->i,_{
    [i.values.map{|i|
       [{_: :a, href: i.url,
          c: {_: :img,
            style:'float:left;max-width:61.8%',
            src: i.url}},
        i.html]},
     (H.css '/css/404')
    ]}
  
  fn 'view/th',->i,e{
    s=e.q['s']||'233'
    i.map{|u,i| u.match(/(gif|jpg|png|tiff)$/i) &&
      {_: :a, href: i.url+'?view=img',
        c: {_: :img, src: i.url+'?'+s+'x'+s}}}}

  F['view/'+MIMEtype+'image/gif'] = F['view/th']
  F['view/'+MIMEtype+'image/jpeg']= F['view/th']
  F['view/'+MIMEtype+'image/png'] = F['view/th']

  fn 'view/imgs',->m,e{ require 'nokogiri'
    h=e.q['h'].do{|h|h.match(/^[0-9]+$/).do{|_|'height:'+h+'px'}}
    seen={}
    x=->i{i&&i.match(/(jpg|gif|png)$/i)&&i}
    [(H.once e,:mu,H.js('/js/mu')),H.js('/js/images'),
     m.values.map{|v|
       [[*v[Content]].map{|c|
          c.class == String &&
         (Nokogiri::HTML.parse(c).do{|c|
            [c.css('img').map{|i|i['src']}.compact,
             c.css(  'a').map{|i|i['href']}.select(&x)]
            })},
        x.(v.uri),
        (v.respond_to?(:values)&&v.values.flatten.map{|v|v.respond_to?(:uri)&&v.uri}.select(&x))
       ].flatten.uniq.compact.map{|s|
         {s: s,c: ->{"<a href='#{v.uri.to_s.do{|u|u.path? ? u : u.E.url}}'><img style='float:left;#{h}' src='#{s}'></a>"}}}}.flatten.map{|i|
       !seen[i[:s]] && (seen[i[:s]]=true; i[:c].())
     }]}

end
