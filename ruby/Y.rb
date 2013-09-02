
# explicit enabling of 'development mode' source-reload on changes
# usage:
# watch __FILE__ 
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

  # call URI-named lambda
  def y *a; F[uri][*a] end

end

# call named-lambda
def Fn a,*g
  E::F[a][*g]
end

# define named-lambda
def fn u,y
  E::F[u.to_s] && puts("w #{u} redefined")
  E::F[u.to_s] = y
end
