watch __FILE__
class R
=begin 
 third-party UIs

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
    [%w{
//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min
//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min
//cdnjs.cloudflare.com/ajax/libs/angular.js/1.1.5/angular.min
//cdnjs.cloudflare.com/ajax/libs/angular-ui/0.4.0/angular-ui.min
//w3.scripts.mit.edu/rdflib.js/dist/rdflib
/common/js/prototype
/common/js/common
/js/fm
}.map{|s| H.js s},
     {class: :editor, id: :editor, c: "editor"},
     {class: 'wac-editor', id: 'wac-editor', c: "wac-edit"},
     {class: :cloudactions},
    ]}

end
