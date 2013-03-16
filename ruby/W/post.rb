#watch __FILE__
class E

  F['view/'+SIOC+'Post']=->d,e{
    [H.once(e,'post',H.css('/css/post')),
     d.map{|u,r|
       r[Content].do{|c|
         [r.except(Content).html,
          {_: :article, c: c}]}}]}

end
