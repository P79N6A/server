#watch __FILE__
class E

  fn 'backtrace',->x,r{
  [500,{'Content-Type'=>'text/html'},
   ['<html><head><title>500</title></head><body><h1>500</h1><pre>',
     [x.class.to_s,x.message,*x.backtrace].join("\n").hrefs,
     '</pre></body></html>']]}

end
