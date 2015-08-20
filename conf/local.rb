class R

  # mount man-handler                on
  GET['/man'] = Man                 # path
  GET['man.whats-your.name/'] = Man # host

end
