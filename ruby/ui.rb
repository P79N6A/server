#watch __FILE__
class R

  # directory-browser and editor
  def warp
    [303, {'Location' => R.warp(@r)}, []]
  end

  def R.warp env
    env['SCHEME']+'://linkeddata.github.io/warp/#/list/'+
    env['SCHEME']+'/'+env['SERVER_NAME']+env['REQUEST_PATH']
  end

  View['warp'] = ->d,e {
    [{_: :script, c: "document.location.href = '#{R.warp e}';"}, # JS
     View['ls'][d,e]]} # !JS

  # generic data-browser and editor
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
