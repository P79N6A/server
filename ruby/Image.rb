class WebResource

  module URIs
    Instagram = 'https://www.instagram.com/'
    YouTube = 'http://www.youtube.com/xml/schemas/2015#'
  end

  # TODO Dedupe video embeds within request
  module Webize

    #TODO imagehost reqtime translation to RDF
    def triplrImage &f
      yield uri, Type, R[Image]
      w,h = Dimensions.dimensions localPath
      yield uri, Stat+'width', w
      yield uri, Stat+'height', h
      triplrFile &f
    end

    def ig
      open(localPath).readlines.map(&:chomp).map{|ig|
        R[Instagram+ig].indexInstagram}
    end

  end
  module HTML

    Markup[Image] = -> image {
      img = image.R
      {class: :thumb,
       c: [{_: :a, href: img.uri,
            c: {_: :img, src: if !img.host # thumbnailify local file
                 img.path + '?preview'
               else
                 img.uri
                end}},'<br>',
           {_: :a, href: img.uri, c: [{_: :span, class: :host, c: img.host}, {_: :span, class: :notes, c: (CGI.escapeHTML img.path)}]}]}}

    Markup[Video] = -> video {
      video = video.R
      if video.match /youtu/
        id = video.q(false)['v'] || video.parts[-1]
        {_: :iframe, width: 560, height: 315, src: "https://www.youtube.com/embed/#{id}", frameborder: 0, gesture: "media", allow: "encrypted-media", allowfullscreen: :true}
      else
        {class: :video,
         c: [{_: :video, src: video.uri, controls: :true}, '<br>',
             {_: :span, class: :notes, c: video.basename}]}
      end}

  end
end
