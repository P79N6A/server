#watch __FILE__
class R

  def POST
    [@r['SERVER_NAME'],""].map{|h| justPath.cascade.map{|p|
        POST[h + p].do{|fn|fn[self,@r].do{|r| return r }}}}

    if @r['CONTENT_TYPE'] == /^application\/x-www-form-urlencoded/
      putForm
    else
      self.PUT
    end
  end

end
