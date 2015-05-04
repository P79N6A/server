class R

  def DELETE
    return [403, {}, ["Forbidden"]] unless allowWrite
    return [409, {}, ["not found"]] unless exist?
    puts "DELETE #{uri}"
    delete
    [200,{
       'Access-Control-Allow-Origin' => @r['HTTP_ORIGIN'].do{|o|o.match(HTTP_URI) && o } || '*',
       'Access-Control-Allow-Credentials' => 'true',
    },[]]
  end

  def delete; node.deleteNode if e; self end

end

class Pathname

  def deleteNode
    FileUtils.send (file?||symlink?) ? :rm : :rmdir, self
    parent.deleteNode if parent.c.empty? # parent now empty, delete it
  end

end
