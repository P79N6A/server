watch __FILE__
class E
  # K.rb - MIME mappings

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

  # MIME-type of dereferenced path
  def mimeP
    puts "mimeP #{uri}"
    o = node.symlink? ? node.readlink.E : self
    puts "location #{o.uri}" unless o.uri == uri
    o.mime
  end

end
