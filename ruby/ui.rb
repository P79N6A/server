watch __FILE__
class R

  GET['/domain'] = -> e,r {
    r.q['view'] ||= 'tabulate'
    nil }

  # generic data-browser
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

  # file-manager
  # https://github.com/linkeddata/ldphp
  View['fm'] = ->d=nil,e=nil {
    i = "//src.whats-your.name/ldphp/www/root/common/images/"
    [%w{
//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min
//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min
//cdnjs.cloudflare.com/ajax/libs/angular.js/1.1.5/angular.min
//cdnjs.cloudflare.com/ajax/libs/angular-ui/0.4.0/angular-ui.min
//w3.scripts.mit.edu/rdflib.js/dist/rdflib
//src.whats-your.name/ldphp/www/root/common/js/prototype
//src.whats-your.name/ldphp/www/root/common/js/common
//src.whats-your.name/ldphp/www/root/common/js/fm
}.map{|s| H.js s},
     {_: :script, c: "cloud.init({request_base:'#{e['SCHEME']+"://"+e['SERVER_NAME']}',request_url:'#{e['REQUEST_PATH']}',user:'#{e.user}'});"},
     {class: :editor, id: :editor, c: :editor, style: "display: none"},
     {class: 'wac-editor', id: 'wac-editor', c: "wac-editor", style: "display: none"},
     {class: :cloudactions,
       c: [
           {_: :img, src: i + "refresh.png", title: :refresh, onclick: "window.location.reload(true);"},
           {_: :img, src: i + "home.png", title: "top level"},
           {_: :img, src: i + "images.png", title: "upload an image"},
           {_: :img, src: i + "add_folder.png", title: "create a folder", onclick: 'showCloudNew("dir");'},
           {_: :img, src: i + "add_file.png", title: "new file"},
           {_: :input, id: 'create-item', class: :item, type: :text, name: "", onkeypress: 'cloudListen(event);', style: "display:none;"},
           {_: :img, id: 'submit-item', src: i + "ok.png", title: :create, style: "display: none"},
           {_: :img, id: 'cancel-item', src: i + "cancel.png", title: :cancel, style: "display: none"},
           {_: :form, id: :imageform, name: :imageform, method: "post", enctype: "multipart/form-data", 
           c: {_: :input, type: :file, id: :addimage, name: :image}},
           {_: :img, id: 'submit-image', src: i + "upload.png", title: :upload, style: "display: none"},
           {_: :img, id: 'cancel-image', src: i + "cancel.png", title: :cancel, style: "display: none"},
          ]},
    ]}

end
