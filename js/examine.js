var e = function(){
    qa('.facet span.name').click(function(e){

	// predicate-object tuple
	var t = e.target

	// predicate
	var a = t.parentNode.parentNode
	var f = a.attr('facet')

	console.log('facet',a.attr('title'),':',t.innerHTML)

	// visual selection status
	if(t.attr('on')){t.removeAttribute('on'); t.style.backgroundColor=''
	            } else { t.attr('on','true'); t.style.backgroundColor='#0f0'}

	// construct selection rules
	var s = [], on = a.querySelectorAll('.name[on=true]')
	if(on.length > 0) {
	    s.push('.'+f+'{display:none}')
	    on.map(function(){
		console.log('on',this.attr('title'))
		s.push('.'+f+'.'+this.attr('title')+'{display:inline}')})}

	// create selected-facet stylesheet
	q('style.'+f) && q('style.'+f).remove()
	q('body').append(el('style').attr('class',f).txt(s.join('\n')))})};

document.addEventListener("DOMContentLoaded", e, false);
