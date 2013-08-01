class E

  class << self
    def console; ARGV.clear; require 'irb'
      IRB.start
    end
  end

  # util, prefix -> tripleStream
  def triplrStdOut e,f='/',g=nil,a=sh

    # leading/trailing whitespace expression
    g ||= /^\s*(.*?)\s*$/

    # exec command
    `#{e} #{a}|grep :`.each_line{|i|

      # key/val separator
      i = i.split /:/

    yield uri, # subject
     (f+(i[0].match(g)||[nil,i[0]])[1].gsub(/\s/,'_')), # predicate
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : v} # object
    }
    nil
  rescue
    nil
  end

end
