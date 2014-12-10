var audio = function(){

    var audio = document.querySelector('#audio')
    var changeTrack = function(i){
	audio.src = decodeURIComponent(i)
	audio.load()}
    audio.on('canplay',function(){audio.play()})

    var hashChange = function(){
	var track = window.location.hash.slice(1)
	if(audio.attr('src') != track) changeTrack(track)
    }

    if(window.location.hash) hashChange()
    window.onhashchange = hashChange

    
}

document.addEventListener("DOMContentLoaded", audio, false);
