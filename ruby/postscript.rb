watch __FILE__
class E

  def triplrPS
    p = E[dirname + '/.' + File.basename(path) + '/']
    unless p.e # && p.m > m 
      p.mk
      `gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r300 -sOutputFile='#{p.sh}%03d.png' -dTextAlphaBits=4 #{sh}`
    end
    yield uri, Content, `ps2txt #{sh}`.hrefs
    p.a('*.png').glob.map{|i|
      yield uri, DC+'Image', i }
  end

  F['view/'+MIMEtype+'application/postscript']=->r,e{
    [(H.once e, :mu,   (H.js '/js/mu')),
     (H.once e, :book, (H.js '/js/book')),
     r.values.map{|d|
      d[DC+'Image'].do{|is|
        is = is.sort_by(&:uri)
        {id: d.uri, type: :book
          c: [{_: :img, style:'float:left;max-width:100%', src: is[0].url},
              is.map{|i|
                [{_: :a, style: 'background-color:#ccc;color:#fff',href: i.url, c: i.E.bare},' ']}]}}}]}

end
