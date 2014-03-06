var book = function(){
    qa('div[type="book"]').on('click',function(e){
	var t = e.target, img = this.querySelector('img'), turn
	if(t.hasAttribute('href')){turn = t}
	if(t.hasAttribute('src')){
	    var pp = this.querySelectorAll('a')
	    var page = this.querySelector('a[href="'+img.attr('src')+'"]')
	    if(e.clientX < (t.width/2)){
		if (page.previousSibling){
		    turn = page.previousSibling
		} else {
		    turn = pp[pp.length-1]
		} 
	    } else {
		if(page.nextSibling){
		    turn = page.nextSibling
		} else {
		    turn = pp[0]
		} 
	    }
	}
	img.attr('src',turn.attr('href'))
	e.preventDefault()
	return false})}

document.addEventListener("DOMContentLoaded", book, false);
