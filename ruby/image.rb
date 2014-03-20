#watch __FILE__
class R

  def triplrImage &f
    yield uri,Type,R[DC+'Image']
#    triplrStdOut 'exiftool', EXIF, &f # slow but detailed
  end

  fn '/thumbnail/GET',->e,r{
    t = R['http://'+r['SERVER_NAME']+e.pathSegment.to_s.sub(/^.thumbnail/,'')]
    puts "thumb #{t}"
    i = [t,t.pathSegment].compact.find(&:f)
    if i && i.size > 0
      stat = i.node.stat
      id = [stat.ino,stat.mtime].h.dive
      path = R['/cache/thumbnail/'+id+'.png']
      if !path.e
        path.dirname.mk
        if i.mimeP.match(/^video/)
          `ffmpegthumbnailer -s 256 -i #{i.sh} -o #{path.sh}`
        else
          `gm convert #{i.sh} -thumbnail "256x256" #{path.sh}`
        end
      end
      path.e ? (path.env r).fileGET : F[E404][e,r]
    else
      F[E404][e,r]
    end}
  
  fn 'view/th',->i,e{
    i.map{|u,i| u && u.match(/(gif|jpe?g|png|tiff)$/i) &&
      {_: :a, href: u, c: {_: :img, src: '/thumbnail' + u.R.pathSegment}}}}

  F['view/'+MIMEtype+'image/gif'] = F['view/th']
  F['view/'+MIMEtype+'image/jpeg']= F['view/th']
  F['view/'+MIMEtype+'image/png'] = F['view/th']

  # display just the images found in content
  fn 'view/imgs',->m, e { seen = {}

    x = ->i{i && i.match(/(jpe?g|gif|png)$/i) && i } # extension match

    m.values.map{|v|
       [[*v[Content]].map{|c| c.class == String &&
         (Nokogiri::HTML.parse(c).do{|c|              # CSS-selector search
            [c.css('img').map{|i|i['src']}.compact,   # <img>
             c.css('a').map{|i|i['href']}.select(&x)] # <a> with image extension
            })},
        x.(v.uri),                                    # subject URI w/ image extension
        (v.respond_to?(:values) &&                    # object URIs w/ image extension
         v.values.flatten.map(&:maybeURI).select(&x))

       ].flatten.uniq.compact.map{|s|
         {uri: s, c: "<a href='#{s}'><img style='float:left;height:255px' src='#{s}'></a>"}}}.flatten.map{|i|

       # show and mark as seen
       !seen[i[:uri]] &&
       (seen[i[:uri]] = true
        i[:c])}}

  def R.c; '#%06x' % rand(16777216) end
  def R.cs; '#%02x%02x%02x' % F['color/hsv2rgb'][rand*6,1,1] end

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
