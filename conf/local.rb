class R

  # man-handler                     on
  GET['/man'] = Man                 # path
  GET['man.whats-your.name/'] = Man # host

  # inbox
  GET['m.whats-your.name/'] = GET['/today']

end
