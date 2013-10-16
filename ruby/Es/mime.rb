watch __FILE__
class E

  # MIME-type, no link-following
  def mime
    @mime ||=
      (t = ext.downcase.to_sym

       if node.symlink?
         "inode/symlink"

       elsif d?
         "inode/directory"

       elsif MIME[t]
         MIME[t]

       elsif Rack::Mime::MIME_TYPES[t='.'+t.to_s]
         Rack::Mime::MIME_TYPES[t]

       elsif base.index('msg.')==0
         "message/rfc822"

       elsif e
         `file --mime-type -b #{sh}`.chomp

       else
         "application/octet-stream"
       end)
  end

  # MIME-type of recursively-dereferenced path
  def mimeP
    @mime ||=
      (p = realpath

       unless p
         nil
       else
         t = ((File.extname p).tail || '').downcase.to_sym

         if p.directory?
           "inode/directory"

         elsif MIME[t]
           MIME[t]
           
         elsif Rack::Mime::MIME_TYPES[t='.'+t.to_s]
           Rack::Mime::MIME_TYPES[t]

         elsif (File.basename p).index('msg.')==0
           "message/rfc822"

         else
           `file --mime-type -b #{Shellwords.escape p.to_s}`.chomp
         end
       end )
  end
end
