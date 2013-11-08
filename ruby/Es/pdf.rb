class E

  def triplrPDF &f

    text = docBase.a '.txt'
    unless text.e && text.m > m
      puts "PDF #{uri}"
      `pdftotext #{sh}`
    end

    # metadata
    triplrStdOut 'pdfinfo', &f

    # body
    yield uri, Content, `cat #{text.sh}`

  end

end
