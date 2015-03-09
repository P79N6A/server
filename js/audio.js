document.addEventListener("DOMContentLoaded", function(){

    var a = document.querySelector('#audio')
    a.addEventListener('canplay',a.play,false)

    var trax = document.querySelectorAll('#sounds .member')

    var select = function(){
	var s = window.location.hash.slice(1) // strip # from URI
	if(s == 'rand') {
	    trax[Math.floor(Math.random() * trax.length)].click()
	} else {
	    a.src = decodeURIComponent(s)
	}
    }
    if(window.location.hash) select()
    window.onhashchange = select

}, false);
