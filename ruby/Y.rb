def watch f
  E::Watch[f]=File.mtime f
  puts 'dev '+f end

class E
  F={}
  Watch={}
  def self.dev; Watch.each{|f,ts|if ts < File.mtime(f); load f end} end
  def y *a; F[uri].(*a) end
end

# URI named functions
def Fn a,*g; E::F[a].(*g) end
def fn u,y
#  E::F[u.to_s] && puts("ww #{u} redefined")
  E::F[u.to_s] = y end
