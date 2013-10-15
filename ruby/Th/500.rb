#watch __FILE__
class E

  fn 'backtrace',->x,r{
  [500,{'Content-Type'=>'text/html'},
   ['<html><head><title>500</title></head><body style="margin:0;font-family: sans-serif;background-color:#000;color:#fff"><h1 style="float:left;height:97%;padding:.2em;margin-right:.5em;background-color:#f00;color:#fbb1;">500</h1><b style="background-color:#fff;color:#000;padding:.1em .25em .1em .25em">' + x.class.to_s,'</b> ' +
    x.message + '<br><table>' +
    x.backtrace.map{|l|
      l.split(/:/).do{|p|
        ['<tr><td style="text-align:right">',p[0],'</td><td>',p[1],'</td><td style="color:#000;background-color:#fff;padding:0 0 0 .33em">',p[2].sub(/^in ./,''),'</td></tr>'].join
      }
    }.join +
     '</table></body></html>']]}

end
