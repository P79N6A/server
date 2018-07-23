class WebResource
  module HTTP
    #host bindings

    # look for app in FDroid
    Host['play.google.com'] = -> re {
      [302,{'Location' => "https://f-droid.org/en/packages/#{re.q['id']}/"},[]]}

    # CSS and fonts

    %w{fonts.googleapis.com fonts.gstatic.com use.typekit.net}.map{|host|
      Host[host] = Font}

    Host['twitter.com'] = Host['www.twitter.com'] = -> re {
      [200,{},[]]
    }

  end
end
