
def watch f
  E::Watch[f]=File.mtime f
  puts 'dev '+f end

class E

  def initialize uri
    @uri = uri.to_s
  end

  def E arg=nil
    if arg
      E.new arg
    else
      self
    end
  end

  def E.[] u; u.E end

  F={}
  Watch={}

  NullView = -> d,e {}

  def self.dev
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  # call lambda @id
  def y *a
    F[uri][*a]
  end

end

# URI -> function

def fn u,y
  E::F[u.to_s] = y
end

def Fn a,*g
  E::F[a][*g]
end

def E e
  E.new e
end
