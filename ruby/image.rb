class R

  GET['/thumbnail'] = -> e,r {
    path = e.path.sub /^.thumbnail/, ''
    path = '//' + r.host + path unless path.match /^.domain/
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
            `ffmpegthumbnailer -s 360 -i #{i.sh} -o #{path.sh}`
          else
            `gm convert #{i.ext.match(/^jpg/) ? 'jpg:' : ''}#{i.sh} -thumbnail "360x360" #{path.sh}`
          end
        end
      end
      path.e ? path.setEnv(r).fileGET : E404[e,r]
    else
      E404[e,r]
    end}

  ViewA[Image] = ->img,e{
    image = img.R
    {_: :a, href: image.uri,
     c: {_: :img, class: :thumb,
         src: if image.ext.downcase == 'gif'
                image.uri
              else
                '/thumbnail' + image.path
              end}}}

  ViewGroup[Image] = -> g,e {
    [{_: :style,
      c: "img.thumb {max-width: 360px; max-height: 360px}"},
     g.map{|u,r|
       ViewA[Image][r,e]}]}

end
