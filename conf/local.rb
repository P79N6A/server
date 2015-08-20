# when placed at server-root, this will load on daemon-start
class R

  # mount man-handler
  GET['/man'] = Man # on a path
  GET['man.whats-your.name/'] # on a host

end
