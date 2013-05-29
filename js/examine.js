var e = function(){
    qa('.facet span.name').click(function(e){

	var t = e.target
	// predicate-object tuple
	var pon = t.parentNode
	// predicate
	var pn = pon.parentNode

	// p+po identifier
	var p = pn.attr('facet')
	var po = pon.attr('facet')

	console.log('facets',pon.innerHTML)

	// visual selection status
	if(pon.attr('on')){pon.removeAttribute('on'); pon.style.backgroundColor=''
	           } else {pon.attr('on','true'); pon.style.backgroundColor='#fff'}

	// construct selection rules
	var s = [], on = p.querySelectorAll('.name[on=true]')
	if(on.length > 0) {
	    s.push('.'+f+'{display:none}')
	    on.map(function(){
		console.log('on',this)
		s.push('.'+f+'.'+this.attr('title')+'{display:inline}')})} // higher specificity for matches

	// create selected-facet stylesheet
	q('style.'+f) && q('style.'+f).remove()
	q('body').append(el('style').attr('class',f).txt(s.join('\n')))})};

document.addEventListener("DOMContentLoaded", e, false);
