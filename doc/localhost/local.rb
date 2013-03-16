watch __FILE__
class E

  fn '/asd/GET',->e,r{
    [303,
     {'Location'=>'/index.html'},[]]}

  fn '/uptime/GET',->e,r{
    H([H.css('/style/main'),{_: :h1, c: r['HTTP_HOST']},'<br>',{class: :uptime, c: `uptime`}]).hR
  }

end
