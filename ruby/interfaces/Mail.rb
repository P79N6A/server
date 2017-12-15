class R
  module Webize
    def triplrMail &b
      m = Mail.read node; return unless m
      id = m.message_id || m.resent_message_id || rand.to_s.sha2 # Message-ID
      puts " MID #{id}" if @verbose
      msgURI = -> id { h=id.sha2; ['', 'msg', h[0], h[1], h[2], id.gsub(/[^a-zA-Z0-9]+/,'.')[0..96], '#this'].join('/').R}
      resource = msgURI[id]; e = resource.uri                # Message URI
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
            dest = msgURI[r]
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
