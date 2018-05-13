# coding: utf-8
class WebResource
  module Webize
    def lines; e ? (open localPath).readlines : [] end

    def triplrArchive &f;     yield uri, Type, R[Stat+'Archive']; triplrFile &f end
    def triplrAudio &f;       yield uri, Type, R[Sound]; triplrFile &f end
    def triplrDataFile &f;    yield uri, Type, R[Stat+'DataFile']; triplrFile &f end

    def triplrBat &f
      yield uri, Content, `pygmentize -l batch -f html #{sh}` end
    def triplrDocker &f
      yield uri, Content, `pygmentize -l docker -f html #{sh}` end
    def triplrIni &f
      yield uri, Content, `pygmentize -l ini -f html #{sh}` end
    def triplrMakefile &f
      yield uri, Content, `pygmentize -l make -f html #{sh}` end
    def triplrLisp &f
      yield uri, Content, `pygmentize -l lisp -f html #{sh}` end
    def triplrShellScript &f
      yield uri, Content, `pygmentize -l sh -f html #{sh}` end
    def triplrRuby &f
      yield uri, Content, `pygmentize -l ruby -f html #{sh}` end
    def triplrCode &f # pygments determines type
      yield uri, Content, `pygmentize -f html #{sh}`
    end

    def triplrWord conv, argB='', &f
      yield uri, Content, '<pre>' + `#{conv} #{sh} #{argB}` + '</pre>'
      triplrFile &f
    end

    def triplrRTF          &f; triplrWord :catdoc,        &f end
    def triplrWordDoc      &f; triplrWord :antiword,      &f end
    def triplrWordXML      &f; triplrWord :docx2txt, '-', &f end
    def triplrOpenDocument &f; triplrWord :odt2txt,       &f end

    def triplrText enc=nil, &f
      doc = stripDoc.uri
      mtime.do{|mt|
        yield doc, Date, mt.iso8601}
      yield doc, Content,
            HTML.render({_: :pre,
                         style: 'white-space: pre-wrap',
                         c: readFile.do{|r|
                           # transcode to UTF-8
                           enc ? r.force_encoding(enc).to_utf8 : r}.
                           hrefs{|p,o| # hypertextify
                           # yield detected links to caller
                           yield doc, p, o
                           yield o.uri, Type, R[Resource]
                         }})
    end
    
    def triplrTeX
      yield stripDoc.uri, Content, `cat #{sh} | tth -r` end

    def triplrMarkdown
      doc = stripDoc.uri
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
  end
end

class String
  def sha2; Digest::SHA2.hexdigest self end
  def to_utf8; encode('UTF-8', undef: :replace, invalid: :replace, replace: '?') end
  def utf8; force_encoding 'UTF-8' end
  def sh; Shellwords.escape self end

  # text -> HTML. (rel,href) tuples yielded to optional code-block
  def hrefs &blk
    # leading/trailing [<>()] stripped, trailing [,.] dropped
    pre, link, post = self.partition(/(https?:\/\/(\([^)>\s]*\)|[,.]\S|[^\s),.”\'\"<>\]])+)/)
    pre.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') + # pre-match
      (link.empty? && '' ||
       '<a class="link" href="' + link.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;') + '">' +
       (resource = link.R
        if blk
          type = case link
                 when /(gif|jpg|jpeg|jpg:large|png|webp)$/i
                   R::Image
                 when /(youtube.com|(mkv|mp4|webm)$)/i
                   R::Video
                 else
                   R::Link
                 end
          yield type, resource
        end
        CGI.escapeHTML(resource.uri.sub /^http:../,'')) +
       '</a>') +
      (post.empty? && '' || post.hrefs(&blk)) # recursion on post-match
  end
end
