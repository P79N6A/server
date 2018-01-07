# coding: utf-8
class WebResource
  module Webize

    def triplrArchive &f; yield uri, Type, R[Stat+'Archive']; triplrFile &f end
    def triplrAudio &f;   yield uri, Type, R[Sound]; triplrFile &f end
    def triplrDataFile &f; yield uri, Type, R[Stat+'DataFile']; triplrFile &f end

    def triplrBat &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l batch -f html #{sh}`; triplrFile &f end
    def triplrDocker &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l docker -f html #{sh}`; triplrFile &f end
    def triplrIni &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l ini -f html #{sh}`; triplrFile &f end
    def triplrMakefile &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l make -f html #{sh}`; triplrFile &f end
    def triplrLisp &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l lisp -f html #{sh}`; triplrFile &f end
    def triplrRuby &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l ruby -f html #{sh}`; triplrFile &f end
    def triplrShellScript &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -l sh -f html #{sh}`; triplrFile &f end
    def triplrSourceCode &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -f html #{sh}`; triplrFile &f end
    def triplrTeX;        yield stripDoc.uri, Content, `cat #{sh} | tth -r` end

    def triplrRTF          &f; triplrWord :catdoc,        &f end
    def triplrWordDoc      &f; triplrWord :antiword,      &f end
    def triplrWordXML      &f; triplrWord :docx2txt, '-', &f end
    def triplrOpenDocument &f; triplrWord :odt2txt,       &f end
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
            HTML.render({_: :pre, style: 'white-space: pre-wrap',
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

    def triplrUriList based=nil
      lines = open(localPath).readlines
      doc = stripDoc.uri
      base = stripDoc.basename
      yield doc, Type, R[Stat+'UriList']
      yield doc, Title, base
      yield doc, Size, lines.size
      yield doc, Date, mtime.iso8601
      prefix = based ? "https://#{base}/" : ''
      lines.map{|line|
        t = line.chomp.split ' '
        uri = prefix + t[0]
        resource = uri.R
        title = t[1..-1].join ' ' if t.size > 1
        yield uri, Type, R[W3+'2000/01/rdf-schema#Resource']
        yield uri, Title, title if title
        yield uri, DC+'note', "#{resource.host.split('.')[0..-2].-(%w{wordpress www}).join('.')} feed" if resource.host && FeedNames.member?(resource.basename)
        yield uri, Label, t[0] if based
      }
    end
  end
end

class String
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end
