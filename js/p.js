document.addEventListener("DOMContentLoaded",function(){

    var viewP=function(){
	var h=[]
	qa('#properties .n').map(function(){
	    if(this.style.color){
		h.push(this.attr('href'))}})
	document.querySelector('#pS').txt(h.length==0 ? '\n' : h.map(function(t){
	    return '*[property="'+t+'"] {display:none}'
	}).join('\n'))}

     document.querySelectorAll('#showP').click(function(e){
	document.querySelectorAll('#properties .n').map(function(){
	    this.style.color=null
	    this.style.backgroundColor=null
	})
	viewP()
	e.preventDefault()
	return false;
    })

     document.querySelectorAll('#hideP').click(function(e){
	document.querySelectorAll('#properties .n').map(function(){
	    this.style.color='#888'
	    this.style.backgroundColor='#fff'
	})
	viewP()
	e.preventDefault()
	return false;
    })

    document.querySelectorAll('#properties .n').click(function(e){
	t = e.target
	if(t.style.color){
	    t.style.color=null
	    t.style.backgroundColor=null
	} else {
	    t.style.color='#888'
	    t.style.backgroundColor='#fff'
	}
	viewP()
	e.preventDefault()
	return false;
    })
    
}, false);


