=begin
 many ways to direct traffic to proxy:
 * default-gateway setting
 * iptables/routing configuration 
 * concatenate proxyhosts to /etc/hosts
 * browser proxy-settings
 * OS proxy-settings
 * see mitmproxy/Squid/Solid docs for ideas
=end

# /etc/hosts uneditable on Android, iOS, app-sandboxes + non-root. ignore it and setup a nameserver-only resolution chain:
require 'resolv-replace'
Resolv::DefaultResolver.
  replace_resolvers([Resolv::DNS.new(:nameserver => '1.1.1.1')])

class WebResource
  module HTTP

    # cache short-link expansion
    Host['bos.gl'] = Host['w.bos.gl'] = Host['t.co'] = -> re {
      host = re.env['HTTP_HOST']
      source = re.env['rack.url_scheme'] + '://' + host + re.path
      dest = nil
      cache = R['/.cache/' + host + (re.path[0..2] || '') + '/' + (re.path[3..-1] || '') + '.u']
      if cache.exist?
        dest = cache.readFile
      else
        dest = (Net::HTTP.get_response (URI.parse source))['location']
        cache.writeFile dest
        puts "#{re.path[1..-1]} -> #{location}"
      end
      [200, {'Content-Type' => 'text/html'}, [re.htmlDocument({re.path => {'source' => source.R, 'dest' => dest.R}})]]
    }

    # URI is encoded in URL, redirect to correct link
    Host['l.instagram.com'] = -> re {
      [302, {'Location' => re.q['u']}, []]}

    # nonlocal fonts/CSS redirected to local
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

# additions to stdlib classes
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
