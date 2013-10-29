watch __FILE__
class E
  
  def triplrMan
    if size < 256e3
      yield uri, Content, `zcat #{sh} | groff -T html -man`
    end
  end

  fn '/man/GET',->e,r{
    puts "Maaan"
    [200,{},[]]
  }


end
