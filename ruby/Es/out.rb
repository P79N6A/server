class E

  Render = 'render/'

  def render mime,   graph, e
   E[Render+ mime].y graph, e
  end

  fn '/E/GET',->e,r{[301,{Location: '/'},[]]}

end
