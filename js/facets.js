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
	if(pon.attr('on')){
	    pon.removeAttribute('on');
	    pon.style.backgroundColor='';
	    pon.style.color='';
	} else {
	    pon.attr('on','true');
	    pon.style.backgroundColor='#0af';
	    pon.style.color='#fff';
	}

	// selection-status rules
	var s = [], on = pn.querySelectorAll('[on=true]')
	if(on.length > 0) {
	    s.push('.'+p+'{display:none}') // lower specificity for predicate class
	    on.map(function(){
		s.push('.'+p+'.'+this.attr('facet')+'{display:inline}')})} // p+o higher specificity

	// apply rules
	q('style.' + p) && q('style.' + p).remove()
	q('body').append(el('style').attr('class',p).txt(s.join('\n')))
    })

};

document.addEventListener("DOMContentLoaded", e, false);
