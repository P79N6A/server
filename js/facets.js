var facets = function(){
    qa('div[facet] > div[facet]').click(function(e){

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
	q('style.'+p) && q('style.'+p).remove() // GC obsolete rules
	
	// build selection-rules
	var s = [], on = pN.querySelectorAll('[on=true]')
	if(on.length > 0) {
	    s.push('.'+p+'{display:none}') // hide this predicate by default
	    on.map(function(){            // only show predicate+object matches
		s.push('.'+p+'.'+this.attr('facet')+'{display:inline}')})

	    // activate rules
	    q('body').append(el('style').attr('class',p).txt(s.join('\n')))
	}
    })
};

document.addEventListener("DOMContentLoaded", facets, false);
