class WebResource
  module HTTP
    #host bindings
    Host['play.google.com'] = -> re {
      [302,
       {'Location' => "https://f-droid.org/en/packages/#{re.q['id']}/"},[]]}

    Host['www.google.com'] = -> re {
      product = re.parts[0]
      case product
      when 'maps'
        loc = if ll = re.path.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
                lat = ll[1]
                lng = ll[2]
                "https://tools.wmflabs.org/geohack/geohack.php?params=#{lat};#{lng}"
              elsif query = (re.q.has_key? 'q')
                "https://www.openstreetmap.org/search?query=#{URI.escape re.q['q']}"
              else
                'https://www.openstreetmap.org/'
              end
        [302,
         {'Location' => loc},[]]
      when 'search'
      else
        [404,{},[]]
      end}

    # original URL on file with third-party
    %w{t.co bit.ly buff.ly bos.gl w.bos.gl dlvr.it ift.tt cfl.re nyti.ms trib.al ow.ly n.pr a.co youtu.be}.map{|host|
      Host[host] = Short}

    # URI is encoded in another URI
    Host['exit.sc'] = Unwrap[:url]
    Host['lookup.t-mobile.com'] = Unwrap[:origURL]
    Host['l.instagram.com'] = Host['images.duckduckgo.com'] = Host['proxy.duckduckgo.com'] = Unwrap[:u]

    # host CSS and fonts locally
    %w{fonts.googleapis.com fonts.gstatic.com use.typekit.net}.map{|host|
      Host[host] = Font}

  end
end
