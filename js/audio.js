document.addEventListener("DOMContentLoaded", function(){

    var a = document.querySelector('#audio')
    a.addEventListener('canplay',a.play,false)

    document.body.addEventListener('keypress',function(e){
	if(e.keyCode == 32){
	    if(a.paused){
		a.play()
	    } else {
		a.pause()
	    }
	}
    },false)

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
