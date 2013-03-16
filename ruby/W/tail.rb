#watch __FILE__

class E

  fn 'req/tail',->e,r{
    Thread.new {r['async.callback'].call [200,{'Content-Type'=>r.format},(E::Tail.new e)]}
  throw :async}

end

class E::Tail
  def initialize e; @e = e end

  def each
    f = @e.glob.map(&:sh).join " "
    IO.popen("tail -fq #{f}"){|f|
      while l = f.gets; yield l end}
  end

end
