class E

  E404 = 'req/' + HTTP + '404'

  fn E404,->e,r{
    r[Type]=[(E HTTP+'404')]; r[Title]=e.uri; r['QUERY']=r.q; r['ACCEPT']=r.accept; r['near']=e.near; r.q.delete 'view'
    %w{CHARSET LANGUAGE ENCODING}.map{|a|r['ACCEPT_'+a]=r.accept_'_'+a}
    [404,{'Content-Type'=> 'text/html'},[H([H.css('/css/404'),r.html])]]}

  fn '/css/404.css/GET',->e,r{
    [200,{'Content-Type'=>'text/css'},
["body {background-color:#010;color:white; font-family: sans-serif}
a {background-color:#1f1;color:#000;text-decoration:none}
td.key {text-align:right}
td.key .frag {font-weight:bold;background-color:#ff0048;color:#000;padding-left:.2em;border-radius:.38em 0 0 .38em}
td.key .abbr {color:#eee;font-size:.92em}
td.val {border-style:dotted;border-width:0 0 .1em 0;border-color:#ff00c6}"]]}

end
