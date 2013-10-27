class E
  
  # show querystring mappings
  fn '/qs/GET',->e,r{H([F['?'].html,H.css('/css/html')]).hR}

  def triplrSourceCode
    m = mime.split(/\//)[-1].sub(/^x-/,'')
    # show line numbers?
    n = @r.has_key?('n') && "--line-number-ref=#{uri.sh}"
    if size < 512e3
      yield uri,Content,
      `source-highlight -f html -o STDOUT -i #{sh} -s #{m} #{n}`
    end
 end

  fn 'view/code',->d,e{[{_: :style, c: 'body{background-color:white;color:black}'},
    d.values.map{|r|[r.E.do{|e|[{_: :a,name: e.uri},e.html(e.base,true)]},'<br>',
                      r[Content]]}]}

  # ls /usr/share/source-highlight/*.lang | xargs -i basename {} .lang | tr "\n" " "
  %w{ada applescript asm awk bat bib bison caml changelog c clipper cobol conf cpp csharp css desktop diff d erlang errors flex fortran function glsl haskell haskell_literate haxe html html_simple java javascript key_string langdef latex ldap lisp log logtalk lsm lua m4 makefile manifest nohilite number outlang oz pascal pc perl php postscript prolog properties proto python ruby scala script_comment sh shellscript slang sml spec sql style symbols tcl texinfo todo url vala vbscript xml}
    .map{|l|
    ma = 'application/' + l
    mt = 'text/x-' + l
    # extension -> MIME
    MIME[l.to_sym] ||= ma
    # triplr/view mappings
    [ma,mt].map{|m|
      MIMEsource[m] ||= [:triplrSourceCode]

      fn 'view/'+m, F['view/code']
  }}

end
