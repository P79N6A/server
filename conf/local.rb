# when placed at server-root, this will load on daemon-start
class R

  # mount man-handler                on
  GET['/man'] = Man                 # path
  GET['man.whats-your.name/'] = man # on a host

end
