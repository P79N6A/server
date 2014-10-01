watch __FILE__
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

      dir = @r.linkHeader['type'] == LDP+'BasicContainer'
      slug = @r['HTTP_SLUG']

      path = if slug
               child slug
             else
               child rand.to_s.h[0..5]
             end

      path.setEnv @r

      if dir
        body = @r['rack.input'].read
        puts body
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
