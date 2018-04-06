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


    Host['t.co'] = -> re {
      [200, {'Content-Type' => 'text/html'}, ["<h1>T.CO"]]        
    }

    # extract URI from URL
    Host['l.instagram.com'] = -> re { [ 302, {'Location' => re.q['u']}, [] ] }

    # fonts. redirect to local font
    Host['fonts.gstatic.com'] = Host['fonts.googleapis.com'] = -> re {
      fontPath = '/.conf/font.woff'
      if re.path == fontPath
        re.fileResponse
      elsif re.path == '/css'
        [200, {'Content-Type' => 'text/css'}, ["body {background-color: #{'#%06x' % (rand 16777216)} !important}\n"]]
      else
        [301, {'Location' => fontPath}, []]
      end}

  end
end
