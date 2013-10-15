class E

  # util, URI prefix, cleaner -> tripleStream
  def triplrStdOut e,f='/',g=/^\s*(.*?)\s*$/,a=sh

    `#{e} #{a}|grep :`.each_line{|i|

      # key/val separator
      i = i.split /:/

    yield uri, # subject
    (f + (i[0].match(g)||[0,i[0]])[1]. # custom identifier-cleaning regex
     gsub(/\s/,'_').gsub(/\//,'-').gsub(/[\(\)]+/,'')), # predicate
      i.tail.join(':').strip.do{|v|v.match(/^[0-9\.]+$/) ? v.to_f : v} # object
    }
    nil
  rescue
    nil
  end

end
