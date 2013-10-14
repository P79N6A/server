class E

  def to_h
    {'uri'=>uri}
  end

  Render = 'render/'

  # render :: MIME, Graph, env -> String
  def render mime, d, e
   E[Render + mimeP].y d,e
  end

end
