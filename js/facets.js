var e = function(){
    qa('div[facet] > div[facet]').click(function(e){

	var poN = this   	// predicate,object
	var pN = poN.parentNode	// predicate

	// facet identifiers
	var p = pN.attr('facet')
	var po = poN.attr('facet')

	// visual selection status
	if(poN.attr('on')){
	    poN.removeAttribute('on');
	    poN.style.backgroundColor='';
	    poN.style.color='';
	} else {
	    poN.attr('on','true');
	    poN.style.backgroundColor='#0af';
	    poN.style.color='#fff';
	}

	q('style.'+p) && q('style.'+p).remove()

	// selection rules
	var s = [], on = pN.querySelectorAll('[on=true]')
	if(on.length > 0) {
	    s.push('.'+p+'{display:none}') // hide this predicate except specific p+o matches
	    on.map(function(){s.push('.'+p+'.'+this.attr('facet')+'{display:inline}')})
	    // update rules
	    q('body').append(el('style').attr('class',p).txt(s.join('\n')))}})
};

document.addEventListener("DOMContentLoaded", e, false);
