class Array
  def justArray; self end
  def intersperse i; inject([]){|a,b|a << b << i}[0..-2] end
end

class FalseClass
  def do; self end
end

class NilClass
  def justArray; [] end
  def do; self end
end

class Object
  def justArray; [self] end
  def id; self end
  def do; yield self end
  def to_time; [Time, DateTime].member?(self.class) ? self : Time.parse(self) end
end

class WebResource
  module HTTP

    # MITMd locations.
    Host['t.co'] = -> re {
      [200, {'Content-Type' => 'text/html'}, ["<h1>T.CO"]]        
    }

    # URI encoded in URL
    Host['l.instagram.com'] = -> re {[302, {'Location' => re.q['u']}, []]}

    # nonlocal fonts. redirect to local
    Host['fonts.gstatic.com'] = Host['fonts.googleapis.com'] = -> re {
      location = '/.conf/font.woff'
      if re.path == location
        re.fileResponse
      elsif re.path == '/css'
        [200, {'Content-Type' => 'text/css'}, []]
      else
        [301, {'Location' => location}, []]
      end}

  end
end
