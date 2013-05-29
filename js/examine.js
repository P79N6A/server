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


	// visual selection status
	if(pon.attr('on')){pon.removeAttribute('on'); pon.style.backgroundColor=''
	           } else {pon.attr('on','true'); pon.style.backgroundColor='#fff'}

	// construct selection rules
	var s = [], on = pn.querySelectorAll('[on=true]')
	if(on.length > 0) {
	    s.push('.'+p+'{display:none}') // lower specificity for predicate class
	    on.map(function(){
		s.push('.'+p+'.'+po+'{display:inline}')})} // higher specificity for p+o selections

	// create selected-facet stylesheet
	q('style.'+p) && q('style.'+p).remove()
	q('body').append(el('style').attr('class',p).txt(s.join('\n')))})};

document.addEventListener("DOMContentLoaded", e, false);
