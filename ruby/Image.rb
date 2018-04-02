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

    Markup[Image] = -> image,env {
      if image.respond_to? :uri
        img = image.R
        if env[:images][img.uri]
        else
          env[:images][img.uri] = true
          {class: :thumb,
           c: {_: :a, href: img.uri,
               c: {_: :img, src: if !img.host # thumbnail
                    img.path + '?preview'
                  else
                    img.uri
                   end}}}
        end
      else
        CGI.escapeHTML image.to_s
      end
    }

    Markup[Video] = -> video,env {
      video = video.R
      if env[:images][video.uri]
      else
        env[:images][video.uri] = true
        if video.match /youtu/
          id = video.q(false)['v'] || video.parts[-1]
          {_: :iframe, width: 560, height: 315, src: "https://www.youtube.com/embed/#{id}", frameborder: 0, gesture: "media", allow: "encrypted-media", allowfullscreen: :true}
        else
          {class: :video,
           c: [{_: :video, src: video.uri, controls: :true}, '<br>',
               {_: :span, class: :notes, c: video.basename}]}
        end
      end
    }

  end
end
