
def watch f
  E::Watch[f]=File.mtime f
  puts 'dev '+f end

class E

  F={}
  Watch={}

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
  puts "#{a} <> #{caller[0]}" unless E::F[a]
  E::F[a][*g]
end
