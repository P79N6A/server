watch __FILE__

class E

  fn '/GET',->e,r{
    html= e.as 'index.html'
    if i.e
      if e.uri[-1] == '/'
        i.env(r).GET_file
      else
        [301, {Location: e.uri.t}, []]
      end
    else
      e.response
    end}


end
