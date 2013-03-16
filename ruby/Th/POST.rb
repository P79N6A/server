class E
  def POST
    as('POST').y(self,@r) || basicPOST
  rescue Exception => x
    Fn 'backtrace',x,@r
  end

  def basicPOST
    
  end

  # mint URI to POSTs here
  fn '/post/POST',->e,r{

    
  }


end
