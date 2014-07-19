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

  # ported from https://github.com/linkeddata/ldphp
  View['fm'] = ->d=nil,e=nil {
    i = "/common/images/"
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
     {class: :cloudactions,
       c: [
           {_: :img, src: i + "refresh.png", title: :refresh},
           {_: :img, src: i + "home.png", title: "top level"},
           {_: :img, src: i + "images.png", title: "upload an image"},
           {_: :img, src: i + "add_folder.png", title: "create a folder", onclick: 'showCloudNew("dir");'},
           {_: :img, src: i + "add_file.png", title: "new file"},
           {_: :input, id: 'create-item', class: :item, type: :text, name: "", onclick: 'cloudListen(event);', style: "display:none;"},
           {_: :img, id: 'submit-item', src: i + "ok.png", title: :create},
           {_: :img, id: 'cancel-item', src: i + "cancel.png", title: :cancel},
           {_: :form, id: :imageform, name: :imageform, method: "post", enctype: "multipart/form-data", 
           c: {_: :input, type: :file, id: :addimage, name: :image}},
           {_: :img, id: 'submit-image', src: i + "upload.png", title: :upload},
           {_: :img, id: 'cancel-image', src: i + "cancel.png", title: :upload},
          ]},
    ]}

end
