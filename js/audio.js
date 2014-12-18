document.addEventListener("DOMContentLoaded", function(){

    var a = document.querySelector('#audio')
    a.addEventListener('canplay',a.play,false)

    var select = function(){
	var s = window.location.hash.slice(1)
	if(a.src != s)
	    a.src = decodeURIComponent(s)}

    if(window.location.hash) select()
    window.onhashchange = select

}, false);
