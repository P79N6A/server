#watch __FILE__

class E

  fn '/GET',->e,r{
    html = e.as 'index.html'
    if html.e
      if e.uri[-1] == '/'
        html.env(r).GET_file
      else
        [301, {Location: e.uri.t}, []]
      end
    else
      e.response
    end}


end
