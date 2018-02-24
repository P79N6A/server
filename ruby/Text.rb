# coding: utf-8
class WebResource
  module Webize

    def triplrArchive &f;     yield uri, Type, R[Stat+'Archive']; triplrFile &f end
    def triplrAudio &f;       yield uri, Type, R[Sound]; triplrFile &f end
    def triplrDataFile &f;    yield uri, Type, R[Stat+'DataFile']; triplrFile &f end
    def triplrBat &f;         yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l batch -f html #{sh}` end
    def triplrDocker &f;      yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l docker -f html #{sh}` end
    def triplrIni &f;         yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l ini -f html #{sh}` end
    def triplrMakefile &f;    yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l make -f html #{sh}` end
    def triplrLisp &f;        yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l lisp -f html #{sh}` end
    def triplrShellScript &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l sh -f html #{sh}` end
    def triplrCode &f;        yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -f html #{sh}` end # let pygments determine file-type
    def triplrTeX;            yield stripDoc.uri, Content, `cat #{sh} | tth -r` end
    def triplrRuby &f
      u = path[0..-4]
      yield u, Type, R[SIOC+'SourceCode']
      yield u, Title, basename
      yield u, Content, `pygmentize -l ruby -f html #{sh}`
      yield u, DC+'cache', self
    end

    def triplrWord conv, argB='', &f
      yield uri, Type, R[Stat+'WordDocument']
      yield uri, Content, '<pre>' + `#{conv} #{sh} #{argB}` + '</pre>'
      triplrFile &f
    end
    def triplrRTF          &f; triplrWord :catdoc,        &f end
    def triplrWordDoc      &f; triplrWord :antiword,      &f end
    def triplrWordXML      &f; triplrWord :docx2txt, '-', &f end
    def triplrOpenDocument &f; triplrWord :odt2txt,       &f end

    def triplrText enc=nil, &f
      doc = stripDoc.uri
      yield doc, Type, R[Stat+'TextFile']
      yield doc, Title, stripDoc.basename
      mtime.do{|mt|
        yield doc, Date, mt.iso8601}
      yield doc, DC+'hasFormat', self
      yield doc, Content,
            HTML.render({_: :pre, style: 'white-space: pre-wrap',
               c: readFile.do{|r| enc ? r.force_encoding(enc).to_utf8 : r}.hrefs})
    rescue Exception => e
      puts uri, e.class, e.message
    end
    
    def triplrMarkdown
      doc = stripDoc.uri
      attr = stripDoc.basename == 'README' ? Abstract : Content
      yield doc, Type, R[Stat+'MarkdownFile']
      yield doc, Title, stripDoc.basename
      yield doc, attr, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile)
      mtime.do{|mt|yield doc, Date, mt.iso8601}
    end
  end
end

class String
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end
