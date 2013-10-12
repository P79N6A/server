class E

  # K.rb for MIME mappings

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

end
