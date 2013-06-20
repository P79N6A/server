class E

  class << self
    def console; ARGV.clear; require 'irb'
      IRB.start
    end
  end

  # util, prefix -> tripleStream
  def triplrStdOut e,f='',g=nil,a=sh;g||=/^\s*(.*?)\s*$/
    `#{e} #{a}|grep :`.each_line{|i|i=i.split /:/
    yield uri,
     (f+(i[0].match(g)||[nil,i[0]])[1].gsub(/\s/,'_')),
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : v}
    };nil
  rescue
    nil
  end

end
