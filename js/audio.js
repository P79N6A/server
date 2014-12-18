document.addEventListener("DOMContentLoaded", function(){

    var audio = document.querySelector('#audio')

    var select = function(){
	var track = window.location.hash.slice(1)
	if(audio.src != track) {
	    audio.src = decodeURIComponent(track)
	    audio.load()
	}
    }

    if(window.location.hash) select()
    window.onhashchange = select

    
}, false);
