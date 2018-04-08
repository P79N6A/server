=begin
 many ways to direct traffic to proxy:

 (port 443) $ setcap 'cap_net_bind_service=+ep' `realpath /usr/bin/python3`
 * default-gateway setting
 * iptables/routing configuration 
 * concatenate proxyhosts to /etc/hosts
 * see mitmproxy/Squid/Solid docs for ideas
 (arbitrary high-port i.e. 8000)
 * browser proxy-settings
 * OS proxy-settings

proxy
 mitmproxy -p 443 --showhost -m reverse:http://localhost --set keep_host_header=true
 
certificates
 cd ~/.mitmproxy/
 openssl x509 -inform PEM -subject_hash_old -in mitmproxy-ca-cert.pem
 su -c 'ln mitmproxy-ca-cert.pem /oreo/system/etc/security/cacerts/c8750f0d.0' # adjust to match above command's hashed-value

=end

class WebResource
  module HTTP

    # URI shorteners
    %w{bit.ly cfl.re ift.tt nyti.ms bos.gl w.bos.gl t.co trib.al}.map{|host|
      Host[host] = Short}

    # URI encoded in URI
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

# additions to stdlib classes:
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
