class WebResource
  # TODO Dedupe video displays per request
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
    def tableCellPhoto
      # scan RDF for not-yet-shown resourcs
      images = []
      images.push self if types.member?(Image) # subject of triple
      self[Image].do{|i|images.concat i}        # object of triple
      images.map(&:R).select{|i|!@r[:images].member? i}.map{|img| # unvisited
        @r[:images].push img # mark visit
        puts "img #{img}"
        {class: :thumb,
         c: [{_: :a, href: (@r['REQUEST_PATH'] != path) ? uri : img.uri, # link to original context first
              c: {_: :img, src: if !img.host || img.host == @r['HTTP_HOST'] # thumbnail if locally-hosted
                   img.path + '?preview'
                 else
                   img.uri
                  end}},'<br>',
             {_: :a, href: img.uri, c: [{_: :span, class: :host, c: img.host}, {_: :span, class: :notes, c: (CGI.escapeHTML img.path)}]}]}}
    end

    def tableCellVideo
      self[Video].map(&:R).map{|video|
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
end
