document.addEventListener("DOMContentLoaded", function(){
    var audio = document.querySelector('#audio');

    audio.addEventListener('canplay',audio.play,false);

    document.addEventListener('keypress',function(e){
	if(e.keyCode == 32){
	    if(audio.paused){
		audio.play()
	    } else {
		audio.pause()
	    }
	}
    },false);

    window.addEventListener('hashchange',function(){
	var id = window.location.hash;
	var href = document.querySelector(id).attr('href');
	audio.src = href;
    });

}, false);
