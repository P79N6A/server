#watch __FILE__
class E

  fn 'backtrace',->x,r{
  [500,{'Content-Type'=>'text/html'},
   ['<html><head><title>500</title><style>div {display:inline}'+"\n"+'.frag {background-color:'+E.cs+';color:#000;font-weight:bold}'+"\n"+'.abbr {color:#000;background-color:#fff}</style></head><body style="margin:0;font-family: sans-serif;background-color:#000;color:#fff"><h1 style="padding:.2em;background-color:#f00;color:#000;margin:0">500</h1><b style="background-color:#fff;color:#000;padding:.1em .25em .1em .25em;">' + x.class.to_s,'</b> ' +
    x.message + '<br><table>' +
    x.backtrace.map{|l|
      l.split(/:/).do{|p|
        ['<tr><td style="text-align:right">',F['abbrURI'][p[0]],'</td><td style="text-align:right">',p[1],'&nbsp;</td><td style="color:#000;background-color:#fff;padding:0 0 0 .33em">',p[2].sub(/^in ./,''),'</td></tr>'].join
      }
    }.join +
     '</table></body></html>']]}

end
