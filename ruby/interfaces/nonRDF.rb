class R
  module Webize
    # MIME mapping
    Triplr = {
      'application/config'   => [:triplrDataFile],
      'application/font'      => [:triplrFile],
      'application/go'   => [:triplrSourceCode],
      'application/haskell'   => [:triplrSourceCode],
      'application/javascript' => [:triplrSourceCode],
      'application/ino'      => [:triplrSourceCode],
      'application/json'      => [:triplrDataFile],
      'application/octet-stream' => [:triplrFile],
      'application/org'      => [:triplrOrg],
      'application/pdf'      => [:triplrFile],
      'application/makefile'      => [:triplrSourceCode],
      'application/msword'   => [:triplrWordDoc],
      'application/msword+xml' => [:triplrWordXML],
      'application/pkcs7-signature' => [:triplrFile],
      'application/rtf'      => [:triplrRTF],
      'application/ruby'     => [:triplrSourceCode],
      'application/sh'      => [:triplrSourceCode],
      'application/x-sh'     => [:triplrSourceCode],
      'application/xml'     => [:triplrDataFile],
      'application/x-executable' => [:triplrFile],
      'application/x-gzip'   => [:triplrArchive],
      'application/vnd.oasis.opendocument.text' => [:triplrOpenDocument],
      'audio/mpeg'           => [:triplrAudio],
      'audio/x-wav'          => [:triplrAudio],
      'audio/3gpp'           => [:triplrAudio],
      'image/bmp'            => [:triplrImage],
      'image/gif'            => [:triplrImage],
      'image/png'            => [:triplrImage],
      'image/svg+xml'        => [:triplrImage],
      'image/tiff'           => [:triplrImage],
      'image/jpeg'           => [:triplrImage],
      'inode/directory'      => [:triplrContainer],
      'message/rfc822'       => [:triplrMail],
      'text/cache-manifest'  => [:triplrText],
      'text/calendar'        => [:triplrCalendar],
      'text/chatlog'         => [:triplrChatLog],
      'text/css'             => [:triplrSourceCode],
      'text/csv'             => [:triplrCSV,/,/],
      'text/html'            => [:triplrHTML],
      'text/man'             => [:triplrMan],
      'text/x-c'             => [:triplrSourceCode],
      'text/x-ruby'          => [:triplrSourceCode],
      'text/x-php'           => [:triplrSourceCode],
      'text/x-python'        => [:triplrSourceCode],
      'text/x-script.ruby'   => [:triplrSourceCode],
      'text/x-script.python' => [:triplrSourceCode],
      'text/x-shellscript'   => [:triplrFile],
      'text/markdown'        => [:triplrMarkdown],
      'text/nfo'             => [:triplrText,'cp437'],
      'text/plain'           => [:triplrText],
      'text/restructured'    => [:triplrMarkdown],
      'text/rtf'             => [:triplrRTF],
      'text/semicolon-separated-values' => [:triplrCSV,/;/],
      'text/tab-separated-values' => [:triplrCSV,/\t/],
      'text/uri-list'        => [:triplrUriList],
      'text/x-tex'           => [:triplrTeX],
    }

    def triplrArchive &f; yield uri, Type, R[Stat+'Archive']; triplrFile &f end
    def triplrAudio &f;   yield uri, Type, R[Sound]; triplrFile &f end
    def triplrHTML &f;    yield uri, Type, R[Stat+'HTMLFile']; triplrFile &f end
    def triplrDataFile &f; yield uri, Type, R[Stat+'DataFile']; triplrFile &f end
    def triplrSourceCode &f; yield uri, Type, R[SIOC+'SourceCode']; yield uri, Content, `pygmentize -f html #{sh}`; triplrFile &f end
    def triplrTeX;        yield stripDoc.uri, Content, `cat #{sh} | tth -r` end
    def triplrRTF          &f; triplrWord :catdoc,        &f end
    def triplrWordDoc      &f; triplrWord :antiword,      &f end
    def triplrWordXML      &f; triplrWord :docx2txt, '-', &f end
    def triplrOpenDocument &f; triplrWord :odt2txt,       &f end

    def triplrFile
      s = path
      size.do{|sz|yield s, Size, sz}
      yield s, Title, basename
      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end

    def triplrContainer
      s = path
      s = s + '/' unless s[-1] == '/'
      yield s, Type, R[Container]
      yield s, Size, children.size
      yield s, Title, basename
      mtime.do{|mt|
        yield s, Mtime, mt.to_i
        yield s, Date, mt.iso8601}
    end

    def triplrUriList
      open(pathPOSIX).readlines.map{|line|
        t = line.chomp.split ' '
        uri = t[0]
        yield uri, Type, R[W3+'2000/01/rdf-schema#Resource']
        yield uri, Title, t[1..-1].join(' ') if t.size > 1 }
    end

    def triplrImage &f
      yield uri, Type, R[Image]
      w,h = Dimensions.dimensions pathPOSIX
      yield uri, Stat+'width', w
      yield uri, Stat+'height', h
      triplrFile &f
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
      yield doc, Type, R[Stat+'TextFile']
      yield doc, Content, ::Redcarpet::Markdown.new(::Redcarpet::Render::Pygment, fenced_code_blocks: true).render(readFile)
      mtime.do{|mt|yield doc, Date, mt.iso8601}
    end

    def triplrCalendar
      cal_file = File.open pathPOSIX
      cals = Icalendar::Calendar.parse(cal_file)
      cal = cals.first
      puts cal
      event = cal.events.first
      puts event
    end

    def triplrCSV d
      ns    = W3 + 'ns/csv#'
      lines = CSV.read pathPOSIX
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

    MessageURI = -> id { h=id.sha2; ['', 'msg', h[0], h[1], h[2], id.gsub(/[^a-zA-Z0-9]+/,'.')[0..96], '#this'].join('/').R}

    def triplrMail &b
      m = Mail.read node; return unless m
      id = m.message_id || m.resent_message_id || rand.to_s.sha2 # Message-ID
      puts " MID #{id}" if @verbose
      resource = MessageURI[id]; e = resource.uri                # Message URI
      puts " URI #{resource}" if @verbose
      srcDir = resource.path.R; srcDir.mkdir # container
      srcFile = srcDir + 'this.msg'          # pathname
      unless srcFile.e
        ln self, srcFile # link canonical-location
        puts "LINK #{srcFile}" if @verbose
      end
      yield e, DC+'identifier', id    # Message-ID as RDF
      yield e, DC+'cache', self + '*' # source-file pointer
      yield e, Type, R[SIOC+'MailMessage'] # RDF type

      # HTML body
      htmlFiles, parts = m.all_parts.push(m).partition{|p|p.mime_type=='text/html'}
      htmlCount = 0
      htmlFiles.map{|p| # HTML file
        html = srcDir + "#{htmlCount}.html"  # file location
        yield e, DC+'hasFormat', html        # file pointer
        unless html.e
          html.writeFile p.decoded  # store HTML email
          puts "HTML #{html}" if @verbose
        end
        htmlCount += 1 } # increment count

      # text/plain body
      parts.select{|p|
        (!p.mime_type || p.mime_type == 'text/plain') && # text parts
          Mail::Encodings.defined?(p.body.encoding)      # decodable?
      }.map{|p|
        yield e, Content, (H p.decoded.to_utf8.lines.to_a.map{|l| # split lines
                             l = l.chomp # strip any remaining [\n\r]
                             if qp = l.match(/^((\s*[>|]\s*)+)(.*)/) # quoted line
                               depth = (qp[1].scan /[>|]/).size # > count
                               if qp[3].empty? # drop blank quotes
                                 nil
                               else # wrap quotes in <span>
                                 indent = "<span name='quote#{depth}'>&gt;</span>"
                                 {_: :span, class: :quote,
                                  c: [indent * depth,' ',
                                      {_: :span, class: :quoted, c: qp[3].gsub('@','').hrefs{|p,o|yield e, p, o}}]}
                               end
                             else # fresh line
                               [l.gsub(/(\w+)@(\w+)/,'\2\1').hrefs{|p,o|yield e, p, o}]
                             end}.compact.intersperse("\n"))} # join lines

      # recursive messages, digests, forwards, archives..
      parts.select{|p|p.mime_type=='message/rfc822'}.map{|m|
        content = m.body.decoded                   # decode message-part
        f = srcDir + content.sha2 + '.inlined.msg' # message location
        f.writeFile content if !f.e                # store message
        f.triplrMail &b} # triplr on contained message

      # From
      from = []
      m.from.do{|f|
        f.justArray.compact.map{|f|
          puts "FROM #{f}" if @verbose 
          from.push f.to_utf8.downcase}} # queue address for indexing + triple-emitting
      m[:from].do{|fr|
        fr.addrs.map{|a|
          name = a.display_name || a.name # human-readable name
          yield e, Creator, name
          puts "NAME #{name}" if @verbose
        } if fr.respond_to? :addrs}
      m['X-Mailer'].do{|m|
        yield e, SIOC+'user_agent', m.to_s
        puts " MLR #{m}" if @verbose
      }

      # To
      to = []
      %w{to cc bcc resent_to}.map{|p|      # recipient fields
        m.send(p).justArray.map{|r|        # recipient
          puts "  TO #{r}" if @verbose
          to.push r.to_utf8.downcase }}    # queue for indexing
      m['X-BeenThere'].justArray.map{|r|to.push r.to_s} # anti-loop recipient
      m['List-Id'].do{|name|yield e, To, name.decoded.sub(/<[^>]+>/,'').gsub(/[<>&]/,'')} # mailinglist name

      # Subject
      subject = nil
      m.subject.do{|s|
        subject = s.to_utf8.gsub(/\[[^\]]+\]/){|l| yield e, Label, l[1..-2] ; nil }
        yield e, Title, subject}

      # Date
      date = m.date || Time.now rescue Time.now
      date = date.to_time.utc
      dstr = date.iso8601
      yield e, Date, dstr
      dpath = '/' + dstr[0..6].gsub('-','/') + '/msg/' # month
      puts "DATE #{date}\nSUBJ #{subject}" if @verbose && subject

      # index addresses
      [*from,*to].map{|addr|
        user, domain = addr.split '@'
        if user && domain
          apath = dpath + domain + '/' + user # address
          yield e, (from.member? addr) ? Creator : To, R[apath+'#'+user] # To/From triple
          if subject
            slug = subject.scan(/[\w]+/).map(&:downcase).uniq.join('.')[0..63]
            mpath = apath + '.' + dstr[8..-1].gsub(/[^0-9]+/,'.') + slug # time & subject
            mpath = mpath + (mpath[-1] == '.' ? '' : '.')  + 'msg' # file-type extension
            mdir = '../.mail/' + domain + '/' # maildir
            %w{cur new tmp}.map{|c| R[mdir + c].mkdir} # maildir container
            mloc = R[mdir + 'cur/' + id.sha2 + '.msg'] # maildir entry
            iloc = mpath.R # index entry
            [iloc,mloc].map{|loc| loc.dir.mkdir # container
              unless loc.e
                ln self, loc # index link
                puts "LINK #{loc}" if @verbose
              end
            }
          end
        end
      }

      # index bidirectional refs
      %w{in_reply_to references}.map{|ref|
        m.send(ref).do{|rs|
          rs.justArray.map{|r|
            dest = MessageURI[r]
            yield e, SIOC+'reply_of', dest
            destDir = dest.path.R; destDir.mkdir; destFile = destDir+'this.msg'
            # bidirectional reference link
            rev = destDir + id.sha2 + '.msg'
            rel = srcDir + r.sha2 + '.msg'
            if !rel.e # link missing
              if destFile.e # link
                ln destFile, rel rescue nil
              else # missing but symlink in case it appears
                ln_s destFile, rel rescue nil
              end
            end
            ln srcFile, rev if !rev.e rescue nil}}}

      # attachments
      m.attachments.select{|p|Mail::Encodings.defined?(p.body.encoding)}.map{|p| # decodability check
        name = p.filename.do{|f|f.to_utf8.do{|f|!f.empty? && f}} ||                           # explicit name
               (rand.to_s.sha2 + (Rack::Mime::MIME_TYPES.invert[p.mime_type] || '.bin').to_s) # generated name
        file = srcDir + name                     # file location
        unless file.e
          file.writeFile p.body.decoded # store
          puts "FILE #{file}" if @verbose
        end
        yield e, SIOC+'attachment', file         # file pointer
        if p.main_type=='image'                  # image attachments
          yield e, Image, file                   # image link represented in RDF
          yield e, Content,                      # image link represented in HTML
                H({_: :a, href: file.uri, c: [{_: :img, src: file.uri}, p.filename]}) # render HTML
        end }
    end
  end
end
