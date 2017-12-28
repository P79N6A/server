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
  # scan for HTTP URIs in string
  # opening '(' required for ')' capture, <> wrapping stripped, ',' and '.' only match mid-URI:
  # demo on the site (https://demohere) and source-code at https://sourcehere.
  def hrefs &b
    pre,link,post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    u = link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') # escaped URI
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') +    # escaped pre-match
      (link.empty? && '' ||
       '<a class="scanned link" href="' + u + '">' + # hyperlink
       (yield(u.match(/(gif|jpg|jpeg|jpg:large|png|webp)$/i) ? R::Image : R::Link, u.R) if b; '') +
       '</a>') +
      (post.empty? && '' || post.hrefs(&b)) # tail
  end
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end
end
