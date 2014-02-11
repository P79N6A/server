class FalseClass
  def do; false end
end

class NilClass
  def do; nil end
  def html e=nil,g=nil; "" end
  def R; "".R end
end

class Object
  def id; self end
  def do; yield self end
  def maybeURI; nil end
  def justArray; [self] end
end

def watch f
  R::Watch[f]=File.mtime f
  puts 'dev '+f end

class R

  def initialize uri
    @uri = uri.to_s
  end

  def R arg=nil
    if arg
      R.new arg
    else
      self
    end
  end

  def R.[] u; u.R end

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

  # util, prefix, cleaner -> tripleStream
  def triplrStdOut e,f='/',g=/^\s*(.*?)\s*$/,a=sh
    `#{e} #{a}|grep :`.each_line{|i|
      i = i.split /:/
    yield uri, (f + (i[0].match(g)||[0,i[0]])[1].       # s
     gsub(/\s/,'_').gsub(/\//,'-').gsub(/[\(\)]+/,'')), # p
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : v.hrefs}} # o
  rescue
  end

end

# URI -> function

def fn u,y
  R::F[u.to_s] = y
end

def Fn a,*g
  R::F[a][*g]
end

def R e
  R.new e
end
