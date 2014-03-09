class R
  
  def triplrSourceCode
    m = mime.split(/\//)[-1].sub(/^x-/,'')
    yield uri,Content, `source-highlight -f html -s #{m} -i #{sh} -o STDOUT` if size < 512e3
 end

  # ls /usr/share/source-highlight/*.lang | xargs -i basename {} .lang | tr "\n" " "

  %w{ada applescript asm awk bat bib bison caml changelog c clipper cobol conf cpp csharp css
 desktop diff d erlang errors flex fortran function glsl haskell haskell_literate haxe html java
 javascript key_string langdef latex ldap lisp log logtalk lsm lua m4 makefile manifest nohilite
 number outlang oz pascal pc perl php prolog properties proto python ruby scala sh
 shellscript slang sml spec sql style symbols tcl texinfo todo url vala vbscript xml}
    .map{|l|
    ma = 'application/' + l
    mt = 'text/x-' + l
    MIME[l.to_sym] ||= ma # extension mapping
    [ma,mt].map{|m| # triplr/view mappings
      MIMEsource[m] ||= [:triplrSourceCode]}}

  MIMEsource['text/css'] ||= [:triplrSourceCode] # i hear CSS is Turing complete now, http://inamidst.com/whits/2014/formats

end
