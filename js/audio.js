document.addEventListener("DOMContentLoaded", function(){
    var audio = document.querySelector('#audio');

    audio.addEventListener('canplay',audio.play,false);

    document.body.addEventListener('keypress',function(e){
	if(e.keyCode == 32){
	    if(audio.paused){
		audio.play()
	    } else {
		audio.pause()
	    }
	}
    },false);

    window.addEventListener('hashchange',function(){
	audio.src = decodeURIComponent(window.location.hash.slice(1))
    });

}, false);
