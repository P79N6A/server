# 'development mode' reload and view invalidation on changes
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

  # call URI function
  def y *a
    F[uri][*a]
  end

  def pathHandler host, method='GET'
    pathSegment.do{|p|
      paths = p.cascade.map{|path|
        path.uri.t + method }
      [host,""].map{|host|
        paths.map{|path|
          handler = F[host + path]
          return handler if handler
        }}}
    nil
  end

end

# URI-named functions
def fn u,y
  E::F[u.to_s] = y
end
def Fn a,*g
  puts "missing #{a} from #{caller[0]}" unless E::F[a]
  E::F[a][*g]
end
