#watch __FILE__
class R

  def POST

    # custom handler
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    # <form> handler
    if @r['CONTENT_TYPE'] == /^application\/x-www-form-urlencoded/
      putForm
    else

    # LDP handler

      isDir = @r.linkHeader['type'] == LDP+'BasicContainer'
      slug = @r['HTTP_SLUG']
      path = slug ? child(slug).setEnv(@r) : self

      if isDir
        body = @r['rack.input'].read
        path = child(rand.to_s.h[0..6]).setEnv(@r) unless slug

        if !body.empty?
          path.n3.w body
        end
        if !path.e
          path.MKCOL
        else
          [200,@r[:Response].update({Location: path.uri}),[]]
        end

      else
        path.PUT
      end
    end
  end
end
