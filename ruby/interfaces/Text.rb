class WebResource
  module Webize
    include URIs

    def triplrArchive &f; yield uri, Type, R[Stat+'Archive']; triplrFile &f end
    def triplrAudio &f;   yield uri, Type, R[Sound]; triplrFile &f end
    def triplrDataFile &f; yield uri, Type, R[Stat+'DataFile']; triplrFile &f end
    def triplrBat &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l batch -f html #{sh}`; triplrFile &f end
    def triplrDocker &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l docker -f html #{sh}`; triplrFile &f end
    def triplrIni &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l ini -f html #{sh}`; triplrFile &f end
    def triplrMakefile &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l make -f html #{sh}`; triplrFile &f end
    def triplrRuby &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l ruby -f html #{sh}`; triplrFile &f end
    def triplrShellScript &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l sh -f html #{sh}`; triplrFile &f end
    def triplrSourceCode &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -f html #{sh}`; triplrFile &f end
    def triplrTeX;        yield stripDoc.uri, Content, `cat #{sh} | tth -r` end
    def triplrRTF          &f; triplrWord :catdoc,        &f end
    def triplrWordDoc      &f; triplrWord :antiword,      &f end
    def triplrWordXML      &f; triplrWord :docx2txt, '-', &f end
    def triplrOpenDocument &f; triplrWord :odt2txt,       &f end

    def triplrUriList
      open(localPath).readlines.map{|line|
        t = line.chomp.split ' '
        uri = t[0]
        yield uri, Type, R[W3+'2000/01/rdf-schema#Resource']
        yield uri, Title, t[1..-1].join(' ') if t.size > 1 }
    end

    def triplrWord conv, out='', &f
      triplrFile &f
      yield uri, Type, R[Stat+'WordDocument']
      yield uri, Content, '<pre>' +
                          `#{conv} #{sh} #{out}` +
                          '</pre>'
    end

    def triplrText enc=nil, &f
      doc = stripDoc.uri
      yield doc, Type, R[Stat+'TextFile']
      yield doc, Title, stripDoc.basename
      mtime.do{|mt|
        yield doc, Date, mt.iso8601}
      yield doc, DC+'hasFormat', self
      yield doc, Content,
            H({_: :pre, style: 'white-space: pre-wrap',
               c: readFile.do{|r| enc ? r.force_encoding(enc).to_utf8 : r}.hrefs})
    rescue Exception => e
      puts uri, e.class, e.message
    end

    def triplrMarkdown
      doc = stripDoc.uri
      yield doc, Type, R[Stat+'MarkdownFile']
      yield doc, Title, stripDoc.basename
      yield doc, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile)
      mtime.do{|mt|yield doc, Date, mt.iso8601}
    end

    def triplrCSV d
      ns    = W3 + 'ns/csv#'
      lines = CSV.read localPath
      lines[0].do{|fields| # header-row
        yield uri, Type, R[ns+'Table']
        yield uri, ns+'rowCount', lines.size
        lines[1..-1].each_with_index{|row,line|
          row.each_with_index{|field,i|
            id = uri + '#row:' + line.to_s
            yield id, fields[i], field
            yield id, Type, R[ns+'Row']}}}
    end

    def triplrChatLog &f
      linenum = -1
      base = stripDoc
      dir = base.dir
      log = base.uri
      basename = base.basename
      channel = dir + '/' + basename
      network = dir + '/' + basename.split('%23')[0] + '*'
      day = dir.uri.match(/\/(\d{4}\/\d{2}\/\d{2})/).do{|d|d[1].gsub('/','-')}
      readFile.lines.map{|l|
        l.scan(/(\d\d)(\d\d)(\d\d)[\s+@]*([^\(\s]+)[\S]* (.*)/){|m|
          s = base + '#l' + (linenum += 1).to_s
          yield s, Type, R[SIOC+'InstantMessage']
          yield s, Label, m[3]
          yield s, Creator, R['#'+m[3]]
          yield s, To, channel
          yield s, Content, m[4].hrefs{|p, o|
            yield log, p, o
            yield s, p, o
          }
          yield s, Date, day+'T'+m[0]+':'+m[1]+':'+m[2] if day}}
      if linenum > 0 # summarize at log-URI
        yield log, Type, R[SIOC+'ChatLog']
        yield log, Date, mtime.iso8601
        yield log, Creator, channel
        yield log, To, network
        yield log, Title, basename.split('%23')[-1] # channel
        yield log, Size, linenum
      end
    rescue Exception => e
      puts uri, e.class, e.message
    end

  end
end
