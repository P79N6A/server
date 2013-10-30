watch __FILE__

class E

  fn '/GET',->e,r{
    e.as('index.html').do{|i| i.e && # HTML-file index
      ((e.uri[-1]=='/') ? (i.env r).GET_file : # currently in dir?
       [301, {Location: e.uri.t}, []]  )} ||   # rebase to dir
    e.response
  }


end
