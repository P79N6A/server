watch __FILE__
class R

  ChanRecent = []

  F['/chan/GET'] = -> d,e {
    e.q['set'] = 'chan'
    e.q['view'] = 'chan'
    
  }


end
