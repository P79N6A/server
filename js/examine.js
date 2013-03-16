
var e = function(){
    qa('.facet > table').click(function(e){
	var f=e.target.parentNode
	var a=f.parentNode.parentNode.parentNode

	if(f.attr('f')){
	    f.removeAttribute('f'); f.style.backgroundColor=''
	} else {
	    f.attr('f','on'); f.style.backgroundColor='#0f0'}

	var facet=a.attr('title')
	var s=[' ']
	q('style.'+facet).remove()
	var on = a.querySelectorAll('tr[f=on]')
	if(on.length > 0) {
	    s.push('.'+facet+'{display:none}')
	    on.map(function(){s.push('.'+facet+'.'+this.attr('title')+'{display:inline}')})}
	q('body').append(el('style').attr('class',facet).txt(s.join('\n')))
})
};
document.addEventListener("DOMContentLoaded", e, false);
