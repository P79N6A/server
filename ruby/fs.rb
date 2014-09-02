class R

  def triplrInode dirChildren=true, &f
    if directory?
      d = descend.uri
      yield d, Stat+'size', size
      yield d, Stat+'mtime', mtime.to_i
      [R[Stat+'Directory'], R[LDP+'BasicContainer']].map{|type| yield d, Type, type}
      c.sort.map{|c|c.triplrInode false, &f} if dirChildren

    elsif symlink?
      [R[Stat+'Link'], Resource].map{|type| yield uri, Type, type}
      yield uri, Stat+'mtime', Time.now.to_i
      yield uri, Stat+'size', 0
      readlink.do{|t| yield uri, Stat+'target', t.stripDoc}

    else
      yield stripDoc.uri, Type, Resource # generic-resource implied by suffixed-file
      yield uri, Type, R[Stat+'File']
      yield uri, Stat+'size', size
      yield uri, Stat+'mtime', mtime.to_i
    end
  end

  # provide an arg for exceedingly-common case we're reading JSON to return parsed values
  def readFile parseJSON=false
    if f
      if parseJSON
        begin
          JSON.parse File.open(pathPOSIX).read
        rescue Exception => x
          puts "error reading JSON: #{caller} #{uri} #{x}"
          {}
        end
      else
        File.open(pathPOSIX).read
      end
    else
      nil
    end
  end

  def writeFile o,s=false
    dir.mk
    File.open(pathPOSIX,'w'){|f|
      f << (s ? o.to_json : o)}
    self
  rescue Exception => x
    puts caller[0..2],x
    self
  end

  alias_method :r, :readFile
  alias_method :w, :writeFile

end
