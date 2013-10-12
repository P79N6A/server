# watch __FILE__ for 'development mode' reload on changes:
def watch f
  E::Watch[f]=File.mtime f
  puts 'dev '+f end

class E

  F={}
  Watch={}

  # check for source-changes
  def self.dev
    Watch.each{|f,ts|
      if ts < File.mtime(f)
        load f
      end }
  end

  # call URI-named function
  def y *a; F[uri][*a] end

end

# URI-named function
def Fn a,*g
  puts "missing fn #{a}" unless E::F[a]
  E::F[a][*g]
end

# define URI-named function
def fn u,y
  E::F[u.to_s] && puts("#{u} redefined")
  E::F[u.to_s] = y
end
