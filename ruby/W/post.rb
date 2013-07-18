#watch __FILE__
class E

  F['view/'+SIOC+'Post']=->g,r{
    g.map{|u,r|
      r[Content].do{|c|
        [r.except(Content).html,
         {_: :article, c: c}]}}}

end
