var e = function(){
    qa('.facet span.name').click(function(e){

	// predicate-object tuple
	var f = e.target
	// predicate
	var a = f.parentNode.parentNode
	var facet = a.attr('facet')

	// visual selection status
	if(f.attr('on')){f.removeAttribute('on'); f.style.backgroundColor=''
	            } else { f.attr('on','true'); f.style.backgroundColor='#0f0'}

	// construct selection rules
	var s = [], on = a.querySelectorAll('.name[on=true]')
	if(on.length > 0) {
	    s.push('.'+facet+'{display:none}')
	    on.map(function(){s.push('.'+facet+'.'+this.attr('title')+'{display:inline}')})}

	// create selected-facet stylesheet
	q('style.'+facet).remove()
	q('body').append(el('style').attr('class',facet).txt(s.join('\n')))})};

document.addEventListener("DOMContentLoaded", e, false);
