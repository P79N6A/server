class E

  def nokogiri; require 'nokogiri'; Nokogiri::HTML.parse read end

  def css sel
    glob.select(&:f).do{|f|(f.empty? ? [self] : f).map{|r|r.nokogiri.do{|c|c.css(sel).map{|e|
      yield r.uri+'#css:'+sel,Content,e.to_s
          }}}} end

  fn 'graph/css',->d,e,m{
    d.fromStream m,:css,e['sel']}

  MIMEsource['text/css'] ||= [:code]

end

class H

  def H.css a,inline=false
    p=a+'.css'
    inline ? {_: :style, c: p.E.r} :
      {_: :link, href: p, rel: :stylesheet, type: E::MIME[:css]} end

end
