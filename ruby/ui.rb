class R

=begin  third-party UIs

 as default view on a subtree,

 GET['/'] = -> d,e { e.q['view'] ||= 'tabulate'; nil }

=end

  # https://github.com/linkeddata/tabulator

  View['tabulate'] = ->d=nil,e=nil {
    src = 'https://w3.scripts.mit.edu/tabulator/'
    [(H.css src + 'tabbedtab'),(H.js 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min'),(H.js src + 'js/mashup/mashlib'),
"<script>jQuery(document).ready(function() {
    var uri = window.location.href;
    window.document.title = uri;
    var kb = tabulator.kb;
    var subject = kb.sym(uri);
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
});</script>",
     {class: :TabulatorOutline, id: :DummyUUID},{_: :table, id: :outline}]}

  # https://github.com/linkeddata/ldphp

  View['fm'] = ->d=nil,e=nil {
    
  }

end
