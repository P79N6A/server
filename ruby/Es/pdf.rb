class E

  def triplrPDF &f
    yield uri,Content,`pdftotext #{sh}; cat #{docBase.a('.txt').sh}`
    dateNorm :triplrStdOut,'pdfinfo', &f
  end

end
