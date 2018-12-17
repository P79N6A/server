class WebResource
  module HTTP

    def track
      print_header
      case ext
      when 'css'
        [200, {'Content-Type' => 'text/css', 'Content-Length' => 0}, []]
      when 'js'
        [200, {'Content-Type' => 'application/javascript'}, []]
      else
        deny
      end
    end

    # Google
    Host['google.com'] = Host['google.com'] = -> re {re.Google}
    def Google
      case parts[0]
      when 'complete'
        [200, {'Content-Length' => 0}, []]
      when 'maps'
        (if ll = path.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
         lat = ll[1] ; lon = ll[2]
         "https://tools.wmflabs.org/geohack/geohack.php?params=#{lat};#{lon}"
        elsif q.has_key? 'q'
          "https://www.openstreetmap.org/search?query=#{URI.escape q['q']}"
        else
          'https://www.openstreetmap.org/'
         end).do{|loc|
          [302,{'Location' => loc},[]]}
      when 'search'
        cache
      else
        deny
      end
    end
    # YouTube
    Path['/redirect'] = -> re {[302,{'Location' => re.q['q']},[]]}

    # DuckDuckGo
    Path['/iu/']  = -> re {[302,{'Location' => re.q['u']},[]]}
    Path['/iur/'] = -> re {[302,{'Location' => re.q['image_host']},[]]}

  end
end
