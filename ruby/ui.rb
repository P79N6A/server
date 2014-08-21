#watch __FILE__
class R

  # file-browser
  def warp
    [303,
     {'Location' => @r['SCHEME']+'://linkeddata.github.io/warp/#/list/'+
                    @r['SCHEME']+'/'+@r['SERVER_NAME']+@r['REQUEST_PATH']},[]]
  end

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
  
end
