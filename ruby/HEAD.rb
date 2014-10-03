class R

  def HEAD
    self.GET.do{|s, h, b  |
                 [s, h, [] ]}
  end

end
