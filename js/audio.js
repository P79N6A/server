var audio = function(){

    var track = 'a.track'
    var audio = document.querySelector('#media')
    var random = q('#rand')
    var trax = qa(track)

    var changeTrack = function(i){
	var track = decodeURIComponent(i)
	q('title').txt(track)
	q('#info').txt(track).attr('href',track)
	q('#infoPane').attr('src',track+'.html?view=base#'+track)
	audio.src = i
	audio.load()}

    var seek = function(s){
	var pos = audio.currentTime + s
	if (0 <= pos <= audio.duration){
	    audio.currentTime = pos
	}
    }

    var jump = function(){
	var s
	if (random.hasAttribute('r')){
	   s = trax[Math.floor(Math.random()*trax.length)]
	} else {
	    var cur = q(track+'[href="'+audio.attr('src')+'"]')
	    if(cur && (s = cur.nextSibling)) {
		// next bound
	    } else {
		s = q(track)
	    }
	}
	window.location.hash = s.attr('href')}

    var toggleRand = function(e){
	if (random.hasAttribute('r')){
	    random.removeAttr('r').style.backgroundColor='#ddf'
	} else {
	    random.attr('r','r').style.backgroundColor='#33f'}
    }

    var hashChange = function(){
	var track = window.location.hash.slice(1)
	if(audio.attr('src') != track) changeTrack(track)
    }

    random.on("click",toggleRand)
    q('#jump').on("click",jump)
    audio.on("ended",jump)
    if(window.location.hash) hashChange()
    window.onhashchange = hashChange

    trax.on('click',function(e){
	window.location.hash = e.target.attr('href')
	e.preventDefault()
	return false
    })

    audio.on('canplay',function(){audio.play()})
    
    document.addEventListener("keydown",function(e){
	switch(e.keyCode){
	case 37:
	    seek(-30);
	    break;
	case 39:
	    seek(30);
	    break;
	case 32:
	    if(audio.paused){
		audio.play()
	    }else{
		audio.pause()}
	    e.preventDefault()
	    break;
	}},false)
}

document.addEventListener("DOMContentLoaded", audio, false);
