#watch __FILE__
class E

  def triplrImage &f
    triplrStdOut 'exiftool', EXIF, &f
  end
  
  # export EXIF to RDF-in-JSON (recursive)
  def exif
    take.map{|g|
      if g.uri.match /(jpe?g|gif|png)$/i
        e = g.ef
        if !e.e || e.m < g.m
          g.ef.w g.fromStream({},:triplrImage), true
          puts "EXIF #{g} #{g.ef.size} bytes"
        end
      end}
  end

  def thumb?
   mimeP.match(/^(image|video)/) && # is file an image?
   @r.qs.match(/^[0-9]{0,3}x[0-9]{0,3}$/) && # valid dimensions?
    base.match(/^[^.]/) # skip "invisible" images
  end

  def thumb
    E['/E/image/'+
      [no.stat.do{|s|
         [s.ino,s.mtime]},
       @r.qs].h.dive+'.png'].do{|n| n.e ||
      (n.dirname.mk
       mimeP.match(/^video/) &&
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
     (H.css '/css/img')]}
  
  fn 'view/th',->i,e{
    s=e.q['s']||'233'
    i.map{|u,i| u.match(/(gif|jpe?g|png|tiff)$/i) &&
      {_: :a, href: i.url+'?triplr=triplrImage&view=img',
        c: {_: :img, src: i.url+'?'+s+'x'+s}}}}

  F['view/'+MIMEtype+'image/gif'] = F['view/th']
  F['view/'+MIMEtype+'image/jpeg']= F['view/th']
  F['view/'+MIMEtype+'image/png'] = F['view/th']

  # display just the images found in content
  fn 'view/imgs',->m,e{

    # height argument
    h = e.q['h'].do{|h|
      h.match(/^[0-9]+$/).do{|_|'height:'+h+'px'}}

    # visited images
    seen={}

    # extension-based filter
    x=->i{i&&i.match(/(jpe?g|gif|png)$/i)&&i}

    [(H.once e,:mu,H.js('/js/mu')),H.js('/js/images'),
     m.values.map{|v|
       # CSS selector-based search
       [[*v[Content]].map{|c| c.class == String &&
         (Nokogiri::HTML.parse(c).do{|c|
            [# <img> elements
             c.css('img').map{|i|i['src']}.compact,
             # <a> elements with image extensions
             c.css('a').map{|i|i['href']}.select(&x)]
            })},
        # check subject URI for image extension
        x.(v.uri),
        # check object URIs for image extension
        (v.respond_to?(:values) &&
         v.values.flatten.map{|v|
           v.respond_to?(:uri) && v.uri
         }.select(&x))
       ].flatten.uniq.compact.map{|s|
         # view 
         {uri: s,
           # img and  link to containing resource
           c: ->{"<a href='#{v.uri.to_s.do{|u|u.path? ? u : u.E.url}}'><img style='float:left;#{h}' src='#{s}'></a>"}}}}.flatten.map{|i|
       # show and mark as seen
       !seen[i[:uri]] &&
       (seen[i[:uri]] = true
        i[:c].())}]}

end
