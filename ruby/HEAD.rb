class R

  def HEAD # just header
    self.GET.do{|s,h,b|
      [s,h,[]]
    }
  end

end
