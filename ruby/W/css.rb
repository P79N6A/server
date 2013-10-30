require 'nokogiri'
class E

  def nokogiri;  Nokogiri::HTML.parse read end

  MIMEsource['text/css'] ||= [:triplrSourceCode]

end

class H

  def H.css a,inline=false
    p=a+'.css'
    inline ? {_: :style, c: p.E.r} :
      {_: :link, href: p, rel: :stylesheet, type: E::MIME[:css]} end

end
