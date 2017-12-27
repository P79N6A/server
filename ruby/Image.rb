class WebResource
  module Webize
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
end
