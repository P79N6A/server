#watch __FILE__
class R

  def triplrImage &f
    yield uri, Type, R[Image]
  end

  GET['/thumbnail'] = -> e,r {
    path = e.path.sub /^.thumbnail/, ''
    path = '//' + r['SERVER_NAME'] + path unless path.match /^.domain/
    i = R path
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
            `gm convert #{i.ext.match(/^jpg/) ? 'jpg:' : ''}#{i.sh} -thumbnail "256x256" #{path.sh}`
          end
        end
      end
      path.e ? path.setEnv(r).fileGET : E404[e,r]
    else
      E404[e,r]
    end}
  
  ViewA[Image] = ->i,e{{_: :a, href: i.uri, c: {_: :img, class: :thumb, src: '/thumbnail' + i.R.path}}}

  ViewGroup[Image] = -> g,e {
    [{_: :style, c: "img.thumb {max-width: 256px; max-height: 256px}"},
     g.map{|u,r| ViewA[Image][r,e]}]}

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
