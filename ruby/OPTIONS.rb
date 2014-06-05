class R

  def OPTIONS
    methods = 'GET, PUT, POST, OPTIONS, HEAD, MKCOL, DELETE, PATCH'
    h = {
      'Allow' => methods,
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Allow-Methods' => @r['HTTP_ACCESS_CONTROL_REQUEST_METHOD'] || methods,
      'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o} || '*',
      'Accept-Patch' => 'application/json',
      'Accept-Post' => 'text/turtle, text/n3, application/json'}
    @r['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'].do{|r|h['Access-Control-Allow-Headers'] = r}
    [200,h,[]]
  end

end
