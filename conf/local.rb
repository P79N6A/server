class R

  # man-handler                     on
  GET['/man'] = Man                 # path
  GET['man.whats-your.name/'] = Man # host

  # foward root path at host to inbox
  GET['m.whats-your.name/'] = -> e,r {GET['/today'][e,r] if e.path == '/'}

end
