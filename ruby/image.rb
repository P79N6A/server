#watch __FILE__
class R

  def triplrImage &f
    yield uri,Type,R[DC+'Image']
#    triplrStdOut 'exiftool', EXIF, &f # slow but detailed
  end

  GET['/thumbnail'] = -> e,r {
    i = R['//'+r['SERVER_NAME']+e.path.sub(/^.thumbnail/,'')]
    if i.file? && i.size > 0
      if i.ext.match /SVG/i
        path = i
      else
        stat = i.node.stat
        path = R['/cache/thumbnail/' + (R.dive [stat.ino,stat.mtime].h) + '.png']
        if !path.e
          path.dir.mk
          if i.mime.match(/^video/)
            `ffmpegthumbnailer -s 256 -i #{i.sh} -o #{path.sh}`
          else
            `gm convert #{i.sh} -thumbnail "256x256" #{path.sh}`
          end
        end
      end
      path.e ? path.setEnv(r).fileGET : E404[e,r]
    else
      E404[e,r]
    end}
  
  ViewA[DC+'Image'] = ->i,e{ShowImage[i.uri]}

  ShowImage = -> u {{_: :a, href: u, c: {_: :img, src: '/thumbnail' + u.R.justPath}}}

  View['imgs'] = -> m,e { seen = {} # unique images found

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
  def R.cs

    hsv2rgb = -> h,s,v {
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

    '#%02x%02x%02x' % hsv2rgb[rand*6,1,1]
  end

end
