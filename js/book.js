N = NodeList.prototype
E = Element.prototype
N.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a);return this}
E.on = function(b,f){
    this.addEventListener(b,f,false)
    return this}
E.attr = function(a,v){
    if(v){ this.setAttribute(a,String(v))
	   return this
  } else { return this.getAttribute(a)}}

N.on = function(){return this.map(E.on,arguments)}

var book = function(){
    document.querySelectorAll('div[type="book"]').on('click',function(e){
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
