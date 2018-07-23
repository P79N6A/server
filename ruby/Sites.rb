class WebResource
  module HTTP
    #host bindings

    # look for app in FDroid
    Host['play.google.com'] = -> re {
      [302,{'Location' => "https://f-droid.org/en/packages/#{re.q['id']}/"},[]]}

    # direct to preferred search & maps providers
    Host['www.google.com'] = -> re {
      product = re.parts[0]
      case product
      when 'maps'
        loc = if ll = re.path.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
                lat = ll[1]
                lng = ll[2]
                "https://tools.wmflabs.org/geohack/geohack.php?params=#{lat};#{lng}"
              elsif re.q.has_key? 'q'
                "https://www.openstreetmap.org/search?query=#{URI.escape re.q['q']}"
              else
                'https://www.openstreetmap.org/'
              end
        [302,{'Location' => loc},[]]
      when 'search'
        loc = if re.q.has_key? 'q'
                "https://duckduckgo.com/?q=#{URI.escape re.q['q']}"
              else
                'https://duckduckgo.com'
              end
        [302,{'Location' => loc},[]]
      else
        [404,{},[]]
      end}

    # original URL on file at third-party - network lookup

    %w{t.co bit.ly buff.ly bos.gl w.bos.gl dlvr.it ift.tt cfl.re nyti.ms trib.al ow.ly n.pr a.co youtu.be}.map{|host|
      Host[host] = Short}

    # URI encoded in another URI - no network lookup

    Host['exit.sc'] = Unwrap[:url]
    Host['lookup.t-mobile.com'] = Unwrap[:origURL]
    Host['l.instagram.com'] = Host['images.duckduckgo.com'] = Host['proxy.duckduckgo.com'] = Unwrap[:u]

    # CSS and fonts

    %w{fonts.googleapis.com fonts.gstatic.com use.typekit.net}.map{|host|
      Host[host] = Font}

    # image hosts

    Host['snag.gy'] = -> re {
        [302,{'Location' => '//i.snag.gy'+re.path},[]]}

    WrappedImage = -> re {
      img = R['https://'+re.env['HTTP_HOST']+re.path].nokogiri.css('[property="og:image"]')
      [302,{'Location' => img.attr('content').to_s},[]]
    }

    Host['imgur.com'] = WrappedImage

    Host['twitter.com'] = Host['www.twitter.com'] = -> re {
      [200,{},[]]
    }

  end
end
