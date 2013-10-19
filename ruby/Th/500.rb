#watch __FILE__
class E

  fn 'backtrace',->x,r{
  [500,{'Content-Type'=>'text/html'},
   ['<html><head><title>500</title><style>div {display:inline}'+"\n"+'.frag {color:#000;background-color:'+E.cs+';font-weight:bold}</style></head><body style="margin:0;font-family: sans-serif;background-color:#fff;color:#000"><h1 style="padding:.2em;background-color:#f00;color:#fff;margin:0">500</h1><table style="border-spacing:0;margin:0"><tr><td><b style="background-color:#eee;color:#500;padding:.1em .3em .1em .3em;">' + x.class.to_s,'</b></td><td style="background-color:#ddd"></td><td style="background-color:#009;color:#fff">' +
    x.message.hrefs + '</td></tr>' +
    x.backtrace.map{|l|
      l.split(/:/).do{|p|
        ['<tr><td style="text-align:right">',F['abbrURI'][p[0]],'</td><td style="text-align:right;border-color:#000;border-width:0 0 .1em 0;border-style:dotted;background-color:#ddd;color:#000">',p[1],'&nbsp;</td><td style="border-color:#ddd;border-width:0 0 .1em 0;border-style:dotted;padding:.15em;">',p[2..-1].join(':').sub(/^in ./,'').sub(/'$/,'').hrefs,'</td></tr>'].join
      }
    }.join +
     '</table></body></html>']]}

end
