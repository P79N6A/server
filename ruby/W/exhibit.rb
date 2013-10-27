class E
 fn Render+'application/json+exhibit',->d,e{
  fields=e.q['f'].do{|f|f.split /,/}
  {items: d.values.map{|r|
      r.keys.-(['uri']).map{|k|
        f=k.frag.do{|f|(f.gsub /\W/,'').downcase} # alphanumeric id restriction 
        if !fields || (fields.member? f)
          r[f]=r[k][0].to_s # rename fieldnames, unwrap value
          r.delete k unless f==k # cleanup unless id same as before
        else
          r.delete k
        end}
      r[:label]=r.delete 'uri' # requires label only
      r
    }}.to_json}

  fn 'head/exhibit',->d,e{
'<link href="'+e['REQUEST_PATH']+e.q.merge({'format' => 'application/json+exhibit'}).qs+'" type="application/json" rel="exhibit/data" />
<script src="http://api.simile-widgets.org/exhibit/2.2.0/exhibit-api.js?autoCreate=false" type="text/javascript"></script>
<script>SimileAjax.jQuery(document).ready(function(){var fDone=function(){
 window.exhibit = Exhibit.create()
 window.exhibit.configureFromDOM()
 database.getAllProperties().map(function(f){
  if (!f.match(/^(label|content)$/)){
   var a=document.createElement("div")
   document.getElementById("sidebar").appendChild(a)
   var x=Exhibit.ListFacet.create({"expression": "."+f},a,exhibit.getUIContext())
   exhibit.setComponent("facet-"+f, x)}})}
   window.database = Exhibit.Database.create()
   window.database.loadDataLinks(fDone)})</script>'}

  fn 'view/exhibit',->d,e{'<table width="100%"><tr valign="top"><td width="25%" id=sidebar></td><td><div ex:role="view"></div></td></tr></table>'}

end
