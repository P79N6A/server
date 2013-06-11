class E

  F["?"]||={}
  F["?"].update({'pdf'=>
                  {'filter'=>'p',
                    'p'=>'uri,Author,Title,Producer,dc:date,fs:size',
                    'sort'=>'Producer',
                    'view'=>'tab'
                  }})

  def triplrPDF &f
    yield uri,Content,`pdftotext #{sh}; cat #{docBase.a('.txt').sh}`
    dateNorm :triplrStdOut,'pdfinfo', &f
  end

end
