=begin
 many ways to direct traffic to proxy:
 * default-gateway setting
 * iptables/routing configuration 
 * concatenate proxyhosts to /etc/hosts
 * browser proxy-settings
 * OS proxy-settings
 * see mitmproxy/Squid/Solid docs for ideas
=end

class WebResource
  module HTTP

    %w{ift.tt bos.gl w.bos.gl t.co}.map{|host|
      Host[host] = Short}

    # URI encoded in URL. peel it out
    Host['l.instagram.com'] = -> re {[302,{'Location' => re.q['u']},[]]}

    # nonlocal fonts, redirect to local
    Host['fonts.gstatic.com'] = Host['fonts.googleapis.com'] = -> re {
      location = '/.conf/font.woff'
      if re.path == location
        re.fileResponse
      elsif re.path == '/css'
        [200, {'Content-Type' => 'text/css'}, ['body {background-color: pink !important}']]
      else
        [301, {'Location' => location}, []]
      end}

  end
end

# additions to stdlib classesL
# #do conditionally binds var + runs block on non-nil arguments
# #justArray maps nil -> [] and obj -> [obj]
# #intersperse is borrowed from Haskell
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
