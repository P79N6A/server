#watch __FILE__
class R

  def R.dev # scan watched-files for changes
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  def R.call e
    method = e['REQUEST_METHOD']
    return [405, {'Allow' => Allow},[]] unless AllowMethods.member? method
    e.extend Th # add environment util-functions
    dev         # check sourcecode
    e['HTTP_X_FORWARDED_HOST'].do{|h|e['SERVER_NAME']=h}   # use original hostname
    e['SERVER_NAME'] = e['SERVER_NAME'].gsub /[\.\/]+/,'.' # host
    e['SCHEME'] = e['rack.url_scheme']                     # scheme
    p = Pathname.new (URI.unescape e['REQUEST_PATH'].utf8).gsub /\/+/, '/' # path
    path = p.expand_path.to_s                              # interpret path
    path += '/' if path[-1] != '/' && p.to_s[-1] == '/'    # preserve trailing-slash
    resource = R[e['SCHEME']+"://"+e['SERVER_NAME']+path]  # resource
    e[:Links] = []                                         # response links
    e[:Response] = {Daemon: Daemon}                        # response head
    e['uri'] = resource.uri                                # response URI
#   puts e.map{|k,v| [k,v].join ' '} # log request
    resource.setEnv(e).send(method).do{|s,h,b| 
      R.log e,s,h,b # log response
      [s,h,b] } # response
  rescue Exception => x
    E500[x,e]
  end

end
