class E

  def nokogiri; require 'nokogiri'; Nokogiri::HTML.parse read end

  def triplrCSS
    puts "TriplrCSS"
    @r.q['sel'].do{|s|
      (nokogiri.css s).map{|e|
        yield uri+'#css:'+s,Content,e.to_s}}
  end

  MIMEsource['text/css'] ||= [:triplrSourceCode]

end

class H

  def H.css a,inline=false
    p=a+'.css'
    inline ? {_: :style, c: p.E.r} :
      {_: :link, href: p, rel: :stylesheet, type: E::MIME[:css]} end

end
