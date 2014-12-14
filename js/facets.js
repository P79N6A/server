N = NodeList.prototype
E = Element.prototype
N.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a);return this}
E.on = function(b,f){
    this.addEventListener(b,f,false)
    return this}
E.click = function(f){
    this.on('click',f)
    return this}
E.attr = function(a,v){
    if(v){ this.setAttribute(a,String(v))
	   return this
  } else { return this.getAttribute(a)}}
N.click = function(){return this.map(E.click,arguments)}
var facets = function(){
    document.querySelectorAll('div[facet] > div[facet]').click(function(e){

	var poN = this   	// (predicate,object) node
	var pN = poN.parentNode	//         predicate  node

	// facet identifiers
	var p = pN.attr('facet')
	var po = poN.attr('facet')

	// update selection state + visual-feedback
	if(poN.attr('on')){
	    poN.removeAttribute('on');
	    poN.style.backgroundColor='';
	    poN.style.color='';
	} else {
	    poN.attr('on','true');
	    poN.style.backgroundColor='#0af';
	    poN.style.color='#fff';
	}
	document.querySelector('style.'+p) && document.querySelector('style.'+p).remove() // GC obsolete rules
	
	// build selection-rules
	var s = [], on = pN.querySelectorAll('[on=true]')
	if(on.length > 0) {
	    s.push('.'+p+'{display:none}') // hide this predicate by default
	    on.map(function(){            // only show predicate+object matches
		s.push('.'+p+'.'+this.attr('facet')+'{display:inline}')})

	    // activate rules
	    var style = document.createElement('style')
	    style.attr('class',p)
	    style.textContent = s.join('\n')
	    document.querySelector('body').appendChild(style)
	}
    })
};

document.addEventListener("DOMContentLoaded", facets, false);
